---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting the container registry
description: Troubleshoot common problems with your GitLab container registry.
---

Before investigating specific issues, try these troubleshooting steps:

1. Verify that the system clock on your Docker client and GitLab server are synchronized (for example, through NTP).

1. For S3-backed registries, verify your IAM permissions and S3 credentials (including region) are correct.
   For more information, see the [sample IAM policy](https://distribution.github.io/distribution/storage-drivers/s3/).

1. Check for errors in the registry logs (for example, `/var/log/gitlab/registry/current`) and the GitLab production logs
   (for example, `/var/log/gitlab/gitlab-rails/production.log`).

1. Review the NGINX configuration file for the container registry (for example, `/var/opt/gitlab/nginx/conf/gitlab-registry.conf`)
   to confirm which port receives requests.

1. Verify that requests are correctly forwarded to the container registry:

   ```shell
   curl --verbose --noproxy "*" https://<hostname>:<port>/v2/_catalog
   ```

   The response should include a line with `Www-Authenticate: Bearer` containing `service="container_registry"`. For example:

   ```plaintext
   < HTTP/1.1 401 Unauthorized
   < Server: nginx
   < Date: Fri, 07 Mar 2025 08:24:43 GMT
   < Content-Type: application/json
   < Content-Length: 162
   < Connection: keep-alive
   < Docker-Distribution-Api-Version: registry/2.0
   < Www-Authenticate: Bearer realm="https://<hostname>/jwt/auth",service="container_registry",scope="registry:catalog:*"
   < X-Content-Type-Options: nosniff
   <
   {"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":
   [{"Type":"registry","Class":"","Name":"catalog","ProjectPath":"","Action":"*"}]}]}
   * Connection #0 to host <hostname> left intact
   ```

## Error: `... x509: certificate signed by unknown authority`

When using a self-signed certificate with the container registry,
you might encounter a similar error in your CI/CD pipeline jobs:

```plaintext
Error response from daemon: Get registry.example.com/v1/users/: x509: certificate signed by unknown authority
```

This error occurs because the Docker daemon running the command expects
a certificate signed by a recognized Certificate Authority, not a self-signed certificate.

To resolve this error, configure Docker to trust self-signed certificates. For help with the Docker configuration,
see [Configure self-signed certificates](container_registry.md#configure-self-signed-certificates).

For additional information, see [issue 18239](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/18239).

## Docker login attempt fails with: 'token signed by untrusted key'

[Registry relies on GitLab to validate credentials](container_registry.md#container-registry-architecture)
If the registry fails to authenticate valid login attempts, you get the following error message:

```shell
# docker login gitlab.company.com:4567
Username: user
Password:
Error response from daemon: login attempt to https://gitlab.company.com:4567/v2/ failed with status: 401 Unauthorized
```

And more specifically, this appears in the `/var/log/gitlab/registry/current` log file:

```plaintext
level=info
msg="token signed by untrusted key with ID: "TOKE:NL6Q:7PW6:EXAM:PLET:OKEN:BG27:RCIB:D2S3:EXAM:PLET:OKEN""
level=warning msg="error authorizing context: invalid token" go.version=go1.12.7 http.request.host="gitlab.company.com:4567"
http.request.id=74613829-2655-4f96-8991-1c9fe33869b8 http.request.method=GET http.request.remoteaddr=10.72.11.20
http.request.uri="/v2/" http.request.useragent="docker/19.03.2 go/go1.12.8 git-commit/6a30dfc
kernel/3.10.0-693.2.2.el7.x86_64 os/linux arch/amd64 UpstreamClient(Docker-Client/19.03.2 \(linux\))"
```

(Line breaks added for legibility.)

GitLab uses the contents of the certificate key pair's two sides to encrypt the authentication token
for the Registry. This message means that those contents do not align.

Check which files are in use:

- `grep -A6 'auth:' /var/opt/gitlab/registry/config.yml`

  ```yaml
  ## Container registry certificate
     auth:
       token:
         realm: https://gitlab.my.net/jwt/auth
         service: container_registry
         issuer: omnibus-gitlab-issuer
    -->  rootcertbundle: /var/opt/gitlab/registry/gitlab-registry.crt
         autoredirect: false
  ```

- `grep -A9 'Container Registry' /var/opt/gitlab/gitlab-rails/etc/gitlab.yml`

  ```yaml
  ## Container registry key
     registry:
       enabled: true
       host: gitlab.company.com
       port: 4567
       api_url: http://127.0.0.1:5000 # internal address to the registry, is used by GitLab to directly communicate with API
       path: /var/opt/gitlab/gitlab-rails/shared/registry
  -->  key: /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
       issuer: omnibus-gitlab-issuer
       notification_secret:
  ```

The output of these `openssl` commands should match, proving that the cert-key pair is a match:

```shell
/opt/gitlab/embedded/bin/openssl x509 -noout -modulus -in /var/opt/gitlab/registry/gitlab-registry.crt | /opt/gitlab/embedded/bin/openssl sha256
/opt/gitlab/embedded/bin/openssl rsa -noout -modulus -in /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key | /opt/gitlab/embedded/bin/openssl sha256
```

If the two pieces of the certificate do not align, remove the files and run `gitlab-ctl reconfigure`
to regenerate the pair. The pair is recreated using the existing values in `/etc/gitlab/gitlab-secrets.json` if they exist. To generate a new pair,
delete the `registry` section in your `/etc/gitlab/gitlab-secrets.json` before running `gitlab-ctl reconfigure`.

If you have overridden the automatically generated self-signed pair with
your own certificates and have made sure that their contents align, you can delete the 'registry'
section in your `/etc/gitlab/gitlab-secrets.json` and run `gitlab-ctl reconfigure`.

## AWS S3 with the GitLab registry error when pushing large images

When using AWS S3 with the GitLab registry, an error may occur when pushing
large images. Look in the Registry log for the following error:

```plaintext
level=error msg="response completed with error" err.code=unknown err.detail="unexpected EOF" err.message="unknown error"
```

To resolve the error specify a `chunksize` value in the Registry configuration.
Start with a value between `25000000` (25 MB) and `50000000` (50 MB).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['storage'] = {
     's3' => {
       'accesskey' => 'AKIAKIAKI',
       'secretkey' => 'secret123',
       'bucket'    => 'gitlab-registry-bucket-AKIAKIAKI',
       'chunksize' => 25000000
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `config/gitlab.yml`:

   ```yaml
   storage:
     s3:
       accesskey: 'AKIAKIAKI'
       secretkey: 'secret123'
       bucket: 'gitlab-registry-bucket-AKIAKIAKI'
       chunksize: 25000000
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations) for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}

## Supporting older Docker clients

The Docker container registry shipped with GitLab disables the schema1 manifest
by default. If you are still using older Docker clients (1.9 or older), you may
experience an error pushing images. See
[issue 4145](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4145) for more details.

You can add a configuration option for backwards compatibility.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['compatibility_schema1_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit the YAML configuration file you created when you deployed the registry. Add the following snippet:

   ```yaml
   compatibility:
       schema1:
           enabled: true
   ```

1. Restart the registry for the changes to take affect.

{{< /tab >}}

{{< /tabs >}}

## Docker connection error

A Docker connection error can occur when there are special characters in either the group,
project or branch name. Special characters can include:

- Leading underscore
- Trailing hyphen/dash
- Double hyphen/dash

To get around this, you can [change the group path](../../user/group/manage.md#change-a-groups-path),
[change the project path](../../user/project/working_with_projects.md#rename-a-repository) or change the
branch name. Another option is to create a [push rule](../../user/project/repository/push_rules.md) to prevent
this error for the entire instance.

## Image push errors

You might get stuck in retry loops when pushing Docker images, even though `docker login` succeeds.

This issue occurs when NGINX isn't properly forwarding headers to the registry, typically in custom
setups where SSL is offloaded to a third-party reverse proxy.

For more information, see [Docker push through NGINX proxy fails trying to send a 32B layer #970](https://github.com/docker/distribution/issues/970).

To resolve this issue, update your NGINX configuration to enable relative URLs in the registry:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   registry['env'] = {
     "REGISTRY_HTTP_RELATIVEURLS" => true
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit the YAML configuration file you created when you deployed the registry. Add the following snippet:

   ```yaml
   http:
       relativeurls: true
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#self-compiled-installations) for the changes to take effect.

{{< /tab >}}

{{< tab title="Docker Compose" >}}

1. Edit your `docker-compose.yaml` file:

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     registry['env'] = {
       "REGISTRY_HTTP_RELATIVEURLS" => true
     }
   ```

1. If the issue persists, ensure both URLs use HTTPS:

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     external_url 'https://git.example.com'
     registry_external_url 'https://git.example.com:5050'
   ```

1. Save the file and restart the container:

   ```shell
   sudo docker restart gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

## Enable the Registry debug server

You can use the container registry debug server to diagnose problems. The debug endpoint can monitor metrics and health, as well as do profiling.

> [!warning]
> Sensitive information may be available from the debug endpoint.
> Access to the debug endpoint must be locked down in a production environment.

The optional debug server can be enabled by setting the registry debug address
in your `gitlab.rb` configuration.

```ruby
registry['debug_addr'] = "localhost:5001"
```

After adding the setting, [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) to apply the change.

Use curl to request debug output from the debug server:

```shell
curl "localhost:5001/debug/health"
curl "localhost:5001/debug/vars"
```

### Prometheus metrics

Prometheus provides metrics that you can use to monitor and troubleshoot performance issues in your container registry.

The following sections:

- Show you how to enable Prometheus metrics
- Catalog all Prometheus metrics exported by the container registry, organized by component

#### Enable Prometheus metrics

Prerequisites:

- You must [enable the registry debug server](#enable-the-registry-debug-server).

To enable Prometheus metrics, add the following configuration in `gitlab.rb`:

```ruby
# Enable Prometheus metrics
registry['debug'] = {
  'prometheus' => {
    'enabled' => true,
    'path' => '/metrics'
  }
}
```

To apply the change, [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

Use curl to request metrics from the debug server:

```shell
curl "localhost:5001/metrics"
```

#### Notifications Metrics

#### Counters

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_notifications_events_total` | The total number of events. | `type`, `action`, `artifact`, `endpoint` | `type`: `Successes`, `Failures`, `Events`, `Dropped` |
| `registry_notifications_status_total` | The number of HTTP responses per status code received from the notifications endpoint. | `code`, `endpoint` | `code`: HTTP status codes (for example, `200 OK` or `404 Not Found`) |
| `registry_notifications_errors_total` | The number of events that errored during sending. Sending requests might be retried. | `endpoint` | string: `'...'` |
| `registry_notifications_delivery_total` | The number of events delivered or lost. An event is lost once the number of retries is exhausted. | `endpoint`, `delivery_type` | `delivery_type`: `delivered`, `lost` |

#### Gauges

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_notifications_pending` | The gauge of pending events in queue, represented by queue length. | `endpoint` | string: `'...'` |

#### Histograms

| Metric name | Description | Labels | Buckets |
|-------------|-------------|--------|---------|
| `registry_notifications_retries_count` | The histogram of cumulative delivery retries. | `endpoint` | `[0, 1, 2, 3, 5, 10, 15, 20, 30, 50]` |
| `registry_notifications_http_latency_seconds` | The histogram of HTTP delivery latency. | `endpoint` | `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100]` (seconds) |
| `registry_notifications_total_latency_seconds` | The histogram of total delivery latency. | `endpoint` | `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100]` (seconds) |

#### Batched background migration (BBM) metrics

##### Counters

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_bbm_runs_total` | A counter for batched migration worker runs. | None | None |
| `registry_bbm_migrated_tuples_total` | A counter for total batched migration records migrated. | `migration_name`, `migration_id` | string: `'...'` |

##### Gauges

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_bbm_job_batch_size` | A gauge for the batch size of a batched migration job. | `migration_name`, `migration_id` | string: `'...'` |
| `registry_database_bbm_progress_percent` | Background migration progress percentage (0-100). | `migration_id`, `migration_name`, `status` | string: `'...'` |

##### Histograms

| Metric name | Description | Labels | Buckets |
|-------------|-------------|--------|---------|
| `registry_bbm_run_duration_seconds` | A histogram of latencies for batched migration worker runs. | None | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0.5s to 1h) |
| `registry_bbm_job_duration_seconds` | A histogram of latencies for a batched migration job. | `migration_name`, `migration_id` | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0.5s to 1h) |
| `registry_bbm_query_duration_seconds` | A histogram of latencies for batched migration database queries. | `migration_name`, `migration_id` | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0.5s to 1h) |
| `registry_bbm_sleep_duration_seconds` | A histogram of sleep durations between BBM worker runs. | `worker` | `[0.5, 1, 5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200, 86400]` (500ms to 24h) |

#### Database metrics

##### Counters

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_database_queries_total` | A counter for database queries. | `name` | string: `'...'` |
| `registry_database_lb_lsn_cache_hits_total` | A counter for database load balancing LSN cache hits and misses. | `result` | `result`: `hit`, `miss` |
| `registry_database_lb_pool_events_total` | A counter of replicas added or removed from the database load balancer pool. | `event`, `reason` | `event`: `replica_added`, `replica_removed`, `replica_quarantined`, `replica_reintegrated`<br>`reason`: `replication_lag`, `connectivity`, `removed_from_dns`, `discovered` |
| `registry_database_lb_targets_total` | A counter for primary and replica target elections during database load balancing. | `target_type`, `fallback`, `reason` | `target_type`: `primary`, `replica`<br>`fallback`: `true`, `false`<br>`reason`: `selected`, `no_cache`, `no_replica`, `error`, `not_up_to_date`, `all_quarantined` |

##### Gauges

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_database_lb_pool_size` | A gauge for the current number of replicas in the load balancer pool. | None | None |
| `registry_database_lb_pool_status` | A gauge for the current status of each replica in the load balancer pool. | `replica`, `status` | `status`: `online`, `quarantined` |
| `registry_database_lb_lag_bytes` | A gauge for the replication lag in bytes for each replica. | `replica` | string: `'...'` |
| `registry_database_migrations_total` | A gauge for the total number of database migrations (applied + pending) | `migration_type` | `migration_type`: `pre_deployment`, `post_deployment` |
| `registry_database_rows` | A gauge for the number of rows in database tables defined by the `query_name` label. | `query_name` | `query_name`: `gc_blob_review_queue`, `gc_manifest_review_queue`, `gc_blob_review_queue_overdue`, `gc_manifest_review_queue_overdue`, `applied_pre_migrations`, `applied_post_migrations` |

##### Histograms

| Metric name | Description | Labels | Buckets |
|-------------|-------------|--------|---------|
| `registry_database_query_duration_seconds` | A histogram of latencies for database queries. | `name` | Prometheus default buckets. <sup>1</sup> |
| `registry_database_lb_lsn_cache_operation_duration_seconds` | A histogram of latencies for database load balancing LSN cache operations. | `operation`, `error` | `operation`: `set`, `get`<br>`error`: `true`, `false`<br>Prometheus default buckets. <sup>1</sup> |
| `registry_database_lb_lookup_seconds` | A histogram of latencies for database load balancing DNS lookups. | `lookup_type`, `error` | `lookup_type`: `srv`, `host`<br>`error`: `true`, `false`<br>Prometheus default buckets. <sup>1</sup>  |
| `registry_database_lb_lag_seconds` | A histogram of replication lag in seconds for each replica. | `replica` | `[0.001, 0.01, 0.1, 0.5, 1, 5, 10, 20, 30, 60]` (1ms to 60s) |
| `registry_database_row_count_collection_duration_seconds` | A histogram of total duration for collecting all database row count queries in a single run. | None | `[0.1, 0.5, 1, 2, 5, 10, 30, 60]` (100ms to 60s) |

**Footnotes**:

1. Prometheus default buckets values: `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]` (seconds)

#### Garbage collection (GC) metrics

##### Counters

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_gc_runs_total` | A counter for online GC worker runs. | `worker`, `noop`, `error`, `dangling`, `event` | `noop`: `true`, `false`<br>`error`: `true`, `false`<br>`dangling`: `true`, `false` |
| `registry_gc_deletes_total` | A counter of artifacts deleted during online GC. | `backend`, `artifact` | `backend`: `storage`, `database`<br>`artifact`: `blob`, `manifest` |
| `registry_gc_storage_deleted_bytes_total` | A counter for bytes deleted from storage during online GC. | `media_type` | string: `'...'` |
| `registry_gc_postpones_total` | A counter for online GC review postpones. | `worker` | string: `'...'` |

##### Histograms

| Metric name | Description | Labels | Buckets |
|-------------|-------------|--------|---------|
| `registry_gc_run_duration_seconds` | A histogram of latencies for online GC worker runs. | `worker`, `noop`, `error`, `dangling`, `event` | `noop`: `true`, `false`<br>`error`: `true`, `false`<br>`dangling`: `true`, `false`<br>Prometheus default buckets. <sup>1</sup> |
| `registry_gc_delete_duration_seconds` | A histogram of latencies for artifact deletions during online GC. | `backend`, `artifact`, `error` | `backend`: `storage`, `database`<br>`artifact`: `blob`, `manifest`<br>`error`: `true`, `false`<br>Prometheus default buckets. <sup>1</sup> |
| `registry_gc_sleep_duration_seconds` | A histogram of sleep durations between online GC worker runs. | `worker` | `[0.5, 1, 5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200, 86400]` (500ms to 24h) |

**Footnotes**:

1. Prometheus default buckets values: `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]` (seconds)

#### Storage metrics

##### Counters

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_storage_cdn_redirects_total` | A counter of CDN redirections for blob downloads. | `backend`, `bypass`, `bypass_reason` | `bypass`: `true`, `false` |
| `registry_storage_rate_limit_total` | A counter of requests to the storage driver that hit a rate limit. | None | None |
| `registry_storage_storage_backend_retries_total` | A counter of retires made while communicating with storage backend. | `retry_type` | `retry_type`: `native`, `custom` |
| `registry_storage_urlcache_requests_total` | A counter of the URL cache middleware requests. | `result`, `reason` | `result`: `hit`, `miss` |
| `registry_storage_access_tracker_dropped_events` | A counter of dropped events in the access tracker due to timeout. | None | None |

##### Gauges

| Metric name | Description | Labels | Label values |
|-------------|-------------|--------|--------------|
| `registry_storage_object_accesses_topn` | Total accesses for top N most frequently accessed objects. | `top_n` | `top_n`: `1`, `10`, `100`, `1000`, `10000`, `all` |

##### Histograms

| Metric name | Description | Labels | Buckets |
|-------------|-------------|--------|---------|
| `registry_storage_blob_download_bytes` | A histogram of blob download sizes for the storage backend. | `redirect` | `redirect`: `true`, `false`<br>`[524288, 1048576, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 3221225472, 4294967296, 5368709120, 6442450944, 7516192768, 8589934592, 9663676416, 10737418240, 21474836480, 32212254720, 42949672960, 53687091200]` (512KiB to 50GiB) |
| `registry_storage_blob_upload_bytes` | A histogram of new blob upload bytes for the storage backend. | None | `[524288, 1048576, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 3221225472, 4294967296, 5368709120, 6442450944, 7516192768, 8589934592, 9663676416, 10737418240, 21474836480, 32212254720, 42949672960, 53687091200]` (512KiB to 50GiB) |
| `registry_storage_urlcache_object_size` | A histogram of object sizes in the URL cache. | None | `[100, 250, 500, 750, 1000, 1500, 2048, 3072, 5120, 10240]` (100 bytes to 10KiB) |
| `registry_storage_object_accesses_distribution` | Distribution of access counts across all objects. | None | Exponential buckets: `[10, 20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240]` |

## Enable registry debug logs

You can enable debug logs to help troubleshoot issues with the container registry.

> [!warning]
> Debug logs may contain sensitive information such as authentication details, tokens, or repository information.
> Enable debug logs only when necessary, and disable them when troubleshooting is complete.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/var/opt/gitlab/registry/config.yml`:

   ```yaml
   level: debug
   ```

1. Save the file and restart the registry:

   ```shell
   sudo gitlab-ctl restart registry
   ```

This configuration is temporary and is discarded when you run `gitlab-ctl reconfigure`.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   registry:
     log:
       level: debug
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab --namespace <namespace>
   ```

{{< /tab >}}

{{< /tabs >}}

### Enable Registry Prometheus Metrics

If the debug server is enabled, you can also enable Prometheus metrics. This endpoint exposes highly detailed telemetry
related to almost all registry operations.

```ruby
registry['debug'] = {
  'prometheus' => {
    'enabled' => true,
    'path' => '/metrics'
  }
}
```

Use curl to request debug output from Prometheus:

```shell
curl "localhost:5001/debug/metrics"
```

## Tags with an empty name

If using [AWS DataSync](https://aws.amazon.com/datasync/)
to copy the registry data to or between S3 buckets, an empty metadata object is created in the root
path of each container repository in the destination bucket. This causes the registry to interpret
such files as a tag that appears with no name in the GitLab UI and API. For more information, see
[this issue](https://gitlab.com/gitlab-org/container-registry/-/issues/341).

To fix this you can do one of two things:

- Use the AWS CLI [`rm`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/rm.html)
  command to remove the empty objects from the root of each affected repository. Pay special
  attention to the trailing `/` and make sure not to use the `--recursive` option:

  ```shell
  aws s3 rm s3://<bucket>/docker/registry/v2/repositories/<path to repository>/
  ```

- Use the AWS CLI [`sync`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/sync.html)
  command to copy the registry data to a new bucket and configure the registry to use it. This
  leaves the empty objects behind.

## Advanced Troubleshooting

We use a concrete example to illustrate how to
diagnose a problem with the S3 setup.

### Investigate a cleanup policy

If you're unsure why your cleanup policy did or didn't delete a tag, execute the policy line by line
by running the below script from the [Rails console](../operations/rails_console.md).
This can help diagnose problems with the policy.

```ruby
repo = ContainerRepository.find(<repository_id>)
policy = repo.project.container_expiration_policy

tags = repo.tags
tags.map(&:name)

tags.reject!(&:latest?)
tags.map(&:name)

regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex}\\z")
regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex_keep}\\z")

tags.select! { |tag| regex_delete.match?(tag.name) && !regex_retain.match?(tag.name) }

tags.map(&:name)

now = DateTime.current
tags.sort_by! { |tag| tag.created_at || now }.reverse! # Lengthy operation

tags = tags.drop(policy.keep_n)
tags.map(&:name)

older_than_timestamp = ChronicDuration.parse(policy.older_than).seconds.ago

tags.select! { |tag| tag.created_at && tag.created_at < older_than_timestamp }

tags.map(&:name)
```

- The script builds the list of tags to delete (`tags`).
- `tags.map(&:name)` prints a list of tags to remove. This may be a lengthy operation.
- After each filter, check the list of `tags` to see if it contains the intended tags to destroy.

### Unexpected 403 error during push

A user attempted to enable an S3-backed Registry. The `docker login` step went
fine. However, when pushing an image, the output showed:

```plaintext
The push refers to a repository [s3-testing.myregistry.com:5050/root/docker-test/docker-image]
dc5e59c14160: Pushing [==================================================>] 14.85 kB
03c20c1a019a: Pushing [==================================================>] 2.048 kB
a08f14ef632e: Pushing [==================================================>] 2.048 kB
228950524c88: Pushing 2.048 kB
6a8ecde4cc03: Pushing [==>                                                ] 9.901 MB/205.7 MB
5f70bf18a086: Pushing 1.024 kB
737f40e80b7f: Waiting
82b57dbc5385: Waiting
19429b698a22: Waiting
9436069b92a3: Waiting
error parsing HTTP 403 response body: unexpected end of JSON input: ""
```

This error is ambiguous because it's not clear whether the 403 is coming from the
GitLab Rails application, the Docker Registry, or something else. In this
case, because we know that the login succeeded, we probably need to look
at the communication between the client and the Registry.

The REST API between the Docker client and Registry is described
[in the Docker documentation](https://distribution.github.io/distribution/spec/api/). Usually, one would just
use Wireshark or tcpdump to capture the traffic and see where things went
wrong. However, because all communications between Docker clients and servers
are done over HTTPS, it's a bit difficult to decrypt the traffic quickly even
if you know the private key. What can we do instead?

One way would be to disable HTTPS by setting up an
[insecure Registry](https://distribution.github.io/distribution/about/insecure/). This could introduce a
security hole and is only recommended for local testing. If you have a
production system and can't or don't want to do this, there is another way:
use mitmproxy, which stands for Man-in-the-Middle Proxy.

### mitmproxy

[mitmproxy](https://mitmproxy.org/) allows you to place a proxy between your
client and server to inspect all traffic. One wrinkle is that your system
needs to trust the mitmproxy SSL certificates for this to work.

The following installation instructions assume you are running Ubuntu:

1. [Install mitmproxy](https://docs.mitmproxy.org/stable/overview-installation/).
1. Run `mitmproxy --port 9000` to generate its certificates.
   Enter <kbd>Control</kbd>-<kbd>C</kbd> to quit.
1. Install the certificate from `~/.mitmproxy` to your system:

   ```shell
   sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
   sudo update-ca-certificates
   ```

If successful, the output should indicate that a certificate was added:

```shell
Updating certificates in /etc/ssl/certs... 1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d....done.
```

To verify that the certificates are properly installed, run:

```shell
mitmproxy --listen-port 9000
```

This command runs mitmproxy on port `9000`. In another window, run:

```shell
curl --proxy "http://localhost:9000" "https://httpbin.org/status/200"
```

If everything is set up correctly, information is displayed on the mitmproxy window and
no errors are generated by the curl commands.

### Running the Docker daemon with a proxy

For Docker to connect through a proxy, you must start the Docker daemon with the
proper environment variables. The easiest way is to shutdown Docker (for example `sudo initctl stop docker`)
and then run Docker by hand. As root, run:

```shell
export HTTP_PROXY="http://localhost:9000"
export HTTPS_PROXY="http://localhost:9000"
docker daemon --debug # or dockerd --debug
```

This command launches the Docker daemon and proxies all connections through mitmproxy.

### Running the Docker client

Now that we have mitmproxy and Docker running, we can attempt to sign in and
push a container image. You may need to run as root to do this. For example:

```shell
docker login example.s3.amazonaws.com:5050
docker push example.s3.amazonaws.com:5050/root/docker-test/docker-image
```

In the previous example, we see the following trace on the mitmproxy window:

```plaintext
PUT https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/uploads/(UUID)/(QUERYSTRING)
    ← 201 text/plain [no content] 661ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 93ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 101ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 87ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 80ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 62ms
```

This output shows:

- The initial PUT requests went through fine with a `201` status code.
- The `201` redirected the client to the Amazon S3 bucket.
- The HEAD request to the AWS bucket reported a `403 Unauthorized`.

What does this mean? This strongly suggests that the S3 user does not have the right
[permissions to perform a HEAD request](https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html).
The solution: check the [IAM permissions again](https://distribution.github.io/distribution/storage-drivers/s3/).
After the right permissions were set, the error went away.

## Missing `gitlab-registry.key` prevents container repository deletion

If you disable your GitLab instance's container registry and try to remove a project that has
container repositories, the following error occurs:

```plaintext
Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
```

In this case, follow these steps:

1. Temporarily enable the instance-wide setting for the container registry in your `gitlab.rb`:

   ```ruby
   gitlab_rails['registry_enabled'] = true
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.
1. Try the removal again.

If you still can't remove the repository using the common methods, you can use the
[GitLab Rails console](../operations/rails_console.md)
to remove the project by force:

```ruby
# Path to the project you'd like to remove
prj = Project.find_by_full_path(<project_path>)

# The following will delete the project's container registry, so be sure to double-check the path beforehand!
if prj.has_container_registry_tags?
  prj.container_repositories.each { |p| p.destroy }
end
```

## Registry service listens on IPv6 address instead of IPv4

You might see the following error if the `localhost` hostname resolves to a IPv6
loopback address (`::1`) on your GitLab server and GitLab expects the registry service
to be available on the IPv4 loopback address (`127.0.0.1`):

```plaintext
request: "GET /v2/ HTTP/1.1", upstream: "http://[::1]:5000/v2/", host: "registry.example.com:5005"
[error] 1201#0: *13442797 connect() failed (111: Connection refused) while connecting to upstream, client: x.x.x.x, server: registry.example.com, request: "GET /v2/<path> HTTP/1.1", upstream: "http://[::1]:5000/v2/<path>", host: "registry.example.com:5005"
```

To fix the error, change `registry['registry_http_addr']` to an IPv4 address in `/etc/gitlab/gitlab.rb`. For example:

```ruby
registry['registry_http_addr'] = "127.0.0.1:5000"
```

See [issue 5449](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5449) for more details.

## Push failures and high CPU usage with Google Cloud Storage (GCS)

You might get a `502 Bad Gateway` error when pushing container images to a registry that uses GCS as the backend. The registry might also experience CPU usage spikes when pushing large images.

This issue occurs when the registry communicates with GCS using the HTTP/2 protocol.

The workaround is to disable HTTP/2 in your registry deployment by setting the `GODEBUG` environment variable to `http2client=0`.

For more information, see [issue 1425](https://gitlab.com/gitlab-org/container-registry/-/issues/1425).
