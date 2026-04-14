---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting Zoekt
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Limited availability

{{< /details >}}

When working with Zoekt, you might encounter the following issues.
For preliminary debugging:

- [Run a health check](_index.md#run-a-health-check) to understand
  the status of your Zoekt infrastructure.
- [Check indexing status](_index.md#check-indexing-status) with the
  `gitlab-rake gitlab:zoekt:info` Rake task.

## Namespace is not indexed

When you [enable the setting](_index.md#index-root-namespaces-automatically), new namespaces get indexed automatically.
If a namespace is not indexed automatically, inspect the Sidekiq logs to see if the jobs are being processed.
`Search::Zoekt::SchedulingWorker` is responsible for indexing namespaces.

In a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session), you can check:

- Namespaces where Zoekt is not enabled:

  ```ruby
  Namespace.group_namespaces.root_namespaces_without_zoekt_enabled_namespace
  ```

- The status of Zoekt indices:

  ```ruby
  Search::Zoekt::Index.all.pluck(:state, :namespace_id)
  ```

To index a namespace manually, see [set up indexing](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/#configure-zoekt-in-gitlab).

## Error: `SilentModeBlockedError`

You might get a `SilentModeBlockedError` when you try to run exact code search.
This issue occurs when [Silent Mode](../../administration/silent_mode) is enabled on the GitLab instance.

To resolve this issue, ensure Silent Mode is disabled.

## Error: `connections to all backends failing`

In `application_json.log`, you might get the following error:

```plaintext
connections to all backends failing; last error: UNKNOWN: ipv4:1.2.3.4:5678: Trying to connect an http1.x server
```

To resolve this issue, check if you're using any proxies.
If you are, set the IP address of the GitLab server to `no_proxy`:

```ruby
gitlab_rails['env'] = {
  "http_proxy" => "http://proxy.domain.com:1234",
  "https_proxy" => "http://proxy.domain.com:1234",
  "no_proxy" => ".domain.com,IP_OF_GITLAB_INSTANCE,127.0.0.1,localhost"
}
```

`proxy.domain.com:1234` is the domain of the proxy instance and the port.
`IP_OF_GITLAB_INSTANCE` points to the public IP address of the GitLab instance.

You can get this information by running `ip a` and checking one of the following:

- The IP address of the appropriate network interface
- The public IP address of any load balancer you're using

## Out-of-memory errors

Zoekt nodes can run out of memory during search or indexing. Out-of-memory (OOM)
errors are more likely in the webserver. The webserver memory-maps index shards into
physical memory as searches are served, so resident memory grows with index size and
query volume. The symptoms of an OOM error, and the recovery steps required, differ
between the two components. For more information, see
[memory architecture](_index.md#memory-architecture).

### Detect an out-of-memory event

For Kubernetes deployments, check whether a container was killed because
of an OOM error:

```shell
kubectl describe pod <your_pod_name> -n <your_namespace>
```

Look for `OOMKilled` in the `Last State` section and a non-zero `Exit Code`
(typically `137`):

```plaintext
Last State: Terminated
  Reason: OOMKilled
  Exit Code: 137
```

You can also check restart counts across all Zoekt pods:

```shell
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt
```

A high `RESTARTS` count on a pod indicates repeated OOM kills. The label selector
`app=gitlab-zoekt` may differ depending on your chart version or operator configuration.

If you have [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) installed,
you can also monitor these metrics in Prometheus or Grafana:

- `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`: pods terminated due to OOM.
- `kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}`: pods in a crash loop.
- `kube_pod_container_status_restarts_total`: cumulative restart count per container. Rapid increases indicate repeated crashes.

The webserver exposes `process_resident_memory_bytes` at `/metrics` on port `6070`.
If you have configured Prometheus to scrape the webserver pods directly, you can use this
metric to monitor webserver resident memory usage over time.

For VM and bare metal deployments, check the system journal for OOM events:

```shell
sudo journalctl -k | grep -i "oom\|killed process"
```

### Recover from an out-of-memory event

The recovery steps differ depending on which component is experiencing OOM errors.

#### Indexer out-of-memory errors

If the indexer is repeatedly killed due to an OOM error, pause indexing globally to stop
all new indexing work across all nodes while you investigate:

```shell
gitlab-rake gitlab:zoekt:pause_indexing
```

Or pause indexing from the UI:

Prerequisites:

- Administrator access.

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search**.
1. Select the **Pause indexing** checkbox.
1. Select **Save changes**.

After you stabilize the node, resume indexing:

```shell
gitlab-rake gitlab:zoekt:resume_indexing
```

#### Webserver out-of-memory errors

If the webserver is repeatedly killed due to an OOM error, disable Zoekt search while
you investigate. This stops search traffic to the crashing node without affecting indexing.

> [!note]
> When Zoekt search is disabled, code search falls back to basic search mode.
> If Elasticsearch is not available, only project-scope code search is possible in basic
> search mode, which increases load on Gitaly.

Prerequisites:

- Administrator access.

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search**.
1. Clear the **Enable searching** checkbox.
1. Select **Save changes**.

After you stabilize the node, re-enable searching:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search**.
1. Select the **Enable searching** checkbox.
1. Select **Save changes**.

### Reduce memory pressure

If your nodes are sized correctly but still experience memory pressure, adjust
the following settings to reduce memory usage.

#### Reduce parallel indexing processes

Prerequisites:

- Administrator access.

To reduce peak indexer memory, lower the number of parallel processes per indexing task:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search**.
1. Set **Number of parallel processes per indexing task** to `1`.
1. Select **Save changes**.

#### Reduce concurrent indexing tasks

Prerequisites:

- Administrator access.

To reduce how many indexing tasks run at the same time, lower the **Indexing CPU to tasks multiplier** value:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search**.
1. Lower the **Indexing CPU to tasks multiplier** value (for example, to `0.5`).
1. Select **Save changes**.

#### Increase force reindexing probability

The Zoekt webserver memory-maps index shards. Over time, incremental
indexing accumulates many small shards, increasing the number of open mmap handles.
Force reindexing rebuilds indices completely, consolidating shards into fewer,
larger files, which reduces memory overhead.

Prerequisites:

- Administrator access.

To reduce shard accumulation, increase the force reindexing probability:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Exact code search**.
1. Increase the **Probability of random force reindexing (percentage)** value.
   The default is `0.25` (0.25%). For example, set it to `1` to force reindex
   roughly 1 in 100 incremental indexing tasks.
1. Select **Save changes**.

### Right-size the node

If adjusting settings does not resolve repeated OOM events, the node needs more
memory. For guidance on memory allocation based on your index size, see
[sizing recommendations](_index.md#sizing-recommendations).

For Kubernetes deployments, increase the memory request and limit in your Helm
chart `values.yaml`. Make sure the memory limit is at or above the value in
the sizing table for your disk tier.

For VM and bare metal deployments, move to a larger instance type from the
sizing table, or add additional nodes to distribute the index across more
machines.

After resizing, run the health check to confirm the nodes recover:

```shell
gitlab-rake gitlab:zoekt:health
```

## Verify Zoekt node connections

To verify that your Zoekt nodes are properly configured and connected,
in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session):

- Check the total number of configured Zoekt nodes:

  ```ruby
  Search::Zoekt::Node.count
  ```

- Check how many nodes are online:

  ```ruby
  Search::Zoekt::Node.online.count
  ```

Alternatively, you can use the `gitlab:zoekt:info` Rake task.

If the number of online nodes is lower than the number of configured nodes or is zero when nodes are configured,
you might have connectivity issues between GitLab and your Zoekt nodes.

## Debug Zoekt connection errors

When you experience connection issues with Zoekt, it's important to understand
the request flow and systematically verify each component in the architecture.

### Zoekt architecture

Zoekt uses a unified binary (`gitlab-zoekt`) that can operate in two modes:

- Indexer mode for indexing repositories from Gitaly
- Webserver mode for serving search requests

The basic search flow is:

```plaintext
GitLab Rails → Zoekt webserver
```

For Helm chart (Kubernetes) deployments, the architecture
includes additional gateway components for load balancing:

```plaintext
GitLab Rails → external gateway (NGINX) → internal gateway (NGINX) → Zoekt webserver
```

These gateway components are part of the Helm chart deployment,
not internal Zoekt components.
They're NGINX proxies that distribute requests across multiple Zoekt webserver instances
and handle routing, load balancing, and optional TLS termination.

For more information about the Zoekt architecture design, see
[use Zoekt For code search](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/code_search_with_zoekt/).

### Verify network reachability

To verify the Zoekt gateway is reachable from your GitLab Rails pods,
[run a health check](_index.md#run-a-health-check):

```shell
gitlab-rake gitlab:zoekt:health
```

This task verifies connectivity from Rails to Zoekt and reports
the overall status as `HEALTHY`, `DEGRADED`, or `UNHEALTHY`.
If the health check fails, network connectivity issues
might exist between GitLab and your Zoekt infrastructure.

To check the node status and configuration, run the following Rake task:

```shell
gitlab-rake gitlab:zoekt:info
```

To view detailed node information including URLs,
in a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session),
run the following command:

```ruby
# View all node attributes including URLs
Search::Zoekt::Node.all.map(&:attributes)
```

- `search_base_url` should point to the Zoekt webserver or the external gateway in Kubernetes
  (for example, `http://gitlab-zoekt:8080/`).
- `index_base_url` should point to the Zoekt indexer.

If you get a `404` response when you search, requests might not be properly routed.
This error indicates the issue is likely with the gateway configuration
rather than network connectivity.

### Monitor Zoekt logs

For Helm chart (Kubernetes) deployments, monitor Zoekt component logs
to identify connection issues.

`StatefulSet` contains three containers:

```shell
# Monitor webserver logs (search requests from Rails)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-webserver -n <your_namespace>

# Monitor indexer logs (repository indexing)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-indexer -n <your_namespace>

# Monitor internal gateway logs (NGINX proxy between the external gateway and webserver)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-internal-gateway -n <your_namespace>
```

If you're using the external gateway deployment,
you can also monitor external gateway logs:

```shell
# Monitor external gateway logs (NGINX proxy for incoming requests from Rails)
kubectl logs -f deployment/gitlab-zoekt-gateway -c zoekt-external-gateway -n <your_namespace>
```

While you monitor these logs, run test searches from the GitLab UI.
The logs should show the request being processed.
If requests do not appear in the logs, a network routing issue
might exist between Rails and Zoekt.

### Run test searches from the UI

While you monitor Zoekt logs, you can run test searches from the GitLab UI:

- Search in a project for specific nodes.
- Search in a group to query multiple nodes.
- Search globally to query all nodes.

If searches fail, check the Rails application logs for detailed error messages:

```shell
# For installations that use the Linux package
tail -f /var/log/gitlab/gitlab-rails/application_json.log | grep -i zoekt

# For self-compiled installations
tail -f log/application_json.log | grep -i zoekt
```

Look for connection errors, timeouts, or authentication failures that might
indicate network issues between GitLab and your Zoekt infrastructure.

### Verify pod and service status

For Helm chart (Kubernetes) deployments, check the status of your Zoekt pods and services:

```shell
# Check pod status
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt

# Check `StatefulSet` status
kubectl get statefulset gitlab-zoekt -n <your_namespace>

# Check service endpoints
kubectl get endpoints gitlab-zoekt -n <your_namespace>

# Describe the service to see the configuration
kubectl describe service gitlab-zoekt -n <your_namespace>
```

Ensure all pods are in a running state and the service has valid endpoints.
If the pods are not running or the endpoints are missing,
your Zoekt deployment might have configuration issues.

For more information about deployment architecture, see:

- [External gateway deployment configuration](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/deployment.yaml)
- [`StatefulSet` configuration (indexer, webserver, and internal gateway)](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/stateful_sets.yaml)

## Error: `TaskRequest responded with [401]`

In your Zoekt indexer logs, you might see `TaskRequest responded with [401]`.
This error indicates that the Zoekt indexer is failing to authenticate with GitLab.

To resolve this issue, verify that `gitlab-shell-secret` is correctly configured
and matches between your GitLab instance and Zoekt indexer.
For example, the output of the following command must match
`gitlab-shell-secret` in your `gitlab.rb`:

```shell
kubectl get secret gitlab-shell-secret -o jsonpath='{.data.secret}' -n your_zoekt_namespace | base64 -d
```

## Error: `missing selected ALPN property`

When you use an external load balancer in front of the Zoekt gateway,
you might see the following error in your GitLab logs:

```plaintext
rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: credentials: cannot check peer: missing selected ALPN property"
```

This error occurs when the load balancer does not support or advertise
ALPN (Application-Layer Protocol Negotiation) with HTTP/2.
Zoekt relies on gRPC for communication between nodes, which requires HTTP/2 support.

To resolve this issue, do one of the following:

- Enable HTTP/2 support on your load balancer (recommended):

  1. Configure your load balancer to support and advertise HTTP/2 through ALPN:
     - For HAProxy, in your backend, ensure `alpn h2,http/1.1` is configured.
     - For NGINX, in your server block, use:
       - In NGINX 1.25.1 and later, `http2 on;`.
       - In NGINX 1.25.0 and earlier, `listen 443 ssl http2;`.
  1. Verify HTTP/2 support:

     ```shell
     curl --verbose --http2 "https://your-zoekt-gateway-url/health" 2>&1 | grep ALPN
     ```

     You should see output similar to:

     ```plaintext
     * ALPN, server accepted to use h2
     ```

- Use TLS passthrough:

  If your load balancer cannot support HTTP/2, configure the balancer for TLS passthrough.
  The Zoekt gateway can then handle TLS termination directly, which ensures proper ALPN negotiation.
  To use TLS passthrough, configure a valid TLS certificate on the Zoekt gateway:

  1. For Helm chart deployments, in your `values.yaml`, configure the certificate:

     ```yaml
     gateway:
       tls:
         certificate:
           enabled: true
           secretName: zoekt-gateway-cert
     ```

  1. Configure your load balancer to pass through encrypted traffic without terminating TLS.
