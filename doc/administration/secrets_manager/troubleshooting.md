---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting OpenBao
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

For recovery key tasks and break-glass root tokens, see [recovery key management](recovery_key.md).
For Geo failover, see
[Geo disaster recovery](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster).

## Where OpenBao runs

OpenBao always runs in Kubernetes, even when GitLab uses the Linux package. The namespace and
deployment name depend on the installation method:

| Installation method | Namespace | Deployment       | Pod container    |
|---------------------|-----------|------------------|------------------|
| Cloud Native GitLab | `gitlab`  | `gitlab-openbao` | `openbao-server` |
| Linux package       | `openbao` | `openbao`        | `openbao-server` |

These examples use the Cloud Native namespace `gitlab`. For a Linux package
installation, replace `gitlab` with `openbao` in the `kubectl` commands.

OpenBao pods carry the label `app.kubernetes.io/name=openbao`. The active node also carries
`openbao-active=true`.

## Find OpenBao logs

Read the OpenBao logs with `kubectl logs`. The related GitLab Rails and Sidekiq logs are stored
separately, depending on the installation method:

| Source         | Cloud Native GitLab                              | Linux package                                      |
|----------------|--------------------------------------------------|----------------------------------------------------|
| OpenBao server | `kubectl logs` on the `openbao-server` container | `kubectl logs` on the `openbao-server` container   |
| GitLab Rails   | `kubectl logs` on the `webservice` pods          | `/var/log/gitlab/gitlab-rails/production_json.log` |
| Sidekiq        | `kubectl logs` on the `sidekiq` pods             | `/var/log/gitlab/sidekiq/current`                  |
| GitLab Runner  | CI/CD job log in the GitLab UI                   | CI/CD job log in the GitLab UI                     |

OpenBao posts audit events to GitLab and also writes them to the OpenBao pod logs.

### Find the OpenBao pods

To list the OpenBao pods and see which node is active:

```shell
kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao \
  --label-columns openbao-active,openbao-sealed
```

The pod with `OPENBAO-ACTIVE` set to `true` is the active node. The others are standby nodes.

### Check OpenBao status

OpenBao must be unsealed to serve requests. To check, run `bao status` in a pod:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
```

In the output, `Sealed` must be `false`. The active node shows `HA Mode    active` and a standby
node shows `HA Mode    standby`:

```plaintext
Seal Type       static
Initialized     true
Sealed          false
Storage Type    postgresql
HA Enabled      true
HA Mode         active
```

The `sys/seal-status` endpoint reports the same state as `"sealed":false`:

```shell
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao read sys/seal-status"
```

> [!note]
> The `bao` binary is present in the pod. Use `bao read` for endpoint queries from inside the pod.

In the logs, a node that unsealed successfully logs `vault is unsealed`. The active node logs
`acquired lock, enabling active operation` and a standby node logs `entering standby mode`:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server \
  | grep -E "acquired lock, enabling active operation|entering standby mode"
```

### Find errors in a time window

To read OpenBao logs from a time window, use `--since`:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server --since=30m \
  | grep -iE "error|warn|failed"
```

For a Linux package installation, search the Rails and Sidekiq log files by time. The logs are
JSON, one event per line.

> [!note]
> OpenBao writes all output to standard error, so some log platforms tag every line as an error.
> Trust the level in the message body (`[info]`, `[warn]`), not the platform's label.

### GitLab Rails logs

The Rails logs cover secret operations from the UI and GraphQL API, plus the audit callback from
OpenBao.

For a Cloud Native installation:

```shell
kubectl logs -n gitlab -l app=webservice -c webservice \
  | grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs"
```

For a Linux package installation:

```shell
grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs" \
  /var/log/gitlab/gitlab-rails/production_json.log
```

GraphQL operations appear with a `caller_id` such as `graphql:createProjectSecret` or
`graphql:getGroupSecrets`. The audit callback appears as the path
`/api/v4/internal/secrets_manager/audit_logs`.

### Sidekiq logs

The workers that provision, deprovision, and maintain Secrets Manager records run under the
`SecretsManagement::` namespace.

For a Cloud Native installation:

```shell
kubectl logs -n gitlab -l app=sidekiq -c sidekiq | grep "SecretsManagement::"
```

For a Linux package installation:

```shell
grep "SecretsManagement::" /var/log/gitlab/sidekiq/current
```

For provisioning problems, filter for `ProvisionProjectSecretsManagerWorker` or
`ProvisionGroupSecretsManagerWorker`.

### GitLab Runner logs

When a CI/CD job fails to fetch a secret, the cause appears in the job log in the GitLab UI. Search
the job log for these strings:

| String                                           | Meaning                                                            |
|--------------------------------------------------|--------------------------------------------------------------------|
| `Resolving secrets`                              | The runner started resolving the job's secrets.                    |
| `Using "gitlab_secrets_manager" secret resolver` | The runner selected the GitLab Secrets Manager resolver.           |
| `not initialized or sealed Vault server`         | OpenBao is sealed or not initialized.                              |
| `api error: status code 403: permission denied`  | OpenBao rejected the request, often an audience or permission problem. |
| `inline auth JWT is required`                    | The runner could not build the authentication request.            |

### Healthy startup logs

After a restart, the active node logs this sequence. A standby node stops at `vault is unsealed`
and then logs `entering standby mode`. The line format varies by configuration, so match the
message text rather than a prefix.

| Log message                                | Meaning                              | If missing                                            |
|--------------------------------------------|--------------------------------------|-------------------------------------------------------|
| `==> OpenBao server started!`              | The process started and read config. | The pod failed to start. Check the pod events.        |
| `vault is unsealed`                        | Auto-unseal succeeded.               | Auto-unseal failed. Check the unseal secret or KMS.   |
| `acquired lock, enabling active operation` | This node became active.             | No node is active. Check the database and HA lock.    |
| `post-unseal setup complete`               | The active node finished setup.      | Setup did not finish. Check the database connection.  |

### Error messages

OpenBao messages come from the `openbao-server` container. GitLab messages come from the Rails or
Sidekiq logs.

| Container        | Message                                                       | Explanation                                                        | Action                                                              |
|------------------|---------------------------------------------------------------|--------------------------------------------------------------------|---------------------------------------------------------------------|
| `openbao-server` | `cipher: message authentication failed`                       | The seal key cannot decrypt the stored data.                       | For a static unseal, copy the unseal secret from the primary site. For a KMS seal, check the KMS key. See [Troubleshoot Geo deployments](#troubleshoot-geo-deployments). |
| `openbao-server` | `unknown key ID`                                              | The static unseal key ID does not match the data in the database.  | Copy the unseal secret from the primary site. See [Troubleshoot Geo deployments](#troubleshoot-geo-deployments). |
| `openbao-server` | `failed to acquire lock`                                      | A standby node cannot acquire the HA lock on a read-only database. | Expected on a Geo secondary. No action required.                    |
| `openbao-server` | `cannot execute INSERT in a read-only transaction`            | A standby node tried to write to a read replica.                   | Expected on a Geo secondary. Otherwise, make sure OpenBao has write access to the database and check the database permissions. |
| `openbao-server` | `post-unseal upgrade seal keys failed: error="no recovery key found"` | The recovery key was never stored.                         | Harmless. Run `recovery_key:store`. |
| Rails or Sidekiq | `[OpenBao] health check returned unhealthy`                   | OpenBao responded but reported an unhealthy state.                 | Check `bao status` and the OpenBao logs.                            |
| Rails or Sidekiq | `[OpenBao] health check failed`                               | GitLab could not reach OpenBao.                                    | Check connectivity. See [GitLab cannot connect to OpenBao](#gitlab-cannot-connect-to-openbao). |
| Rails or Sidekiq | `Failed to authenticate with OpenBao`                         | OpenBao rejected the JWT.                                          | Check the audience. See [JWT authentication fails](#jwt-authentication-fails). |
| Rails or Sidekiq | `Failed to open TCP connection to <host>:443 (execution expired)` | Sidekiq could not reach the OpenBao URL.                       | Check DNS and the OpenBao URL from a Sidekiq pod.                   |
| Rails or Sidekiq | `SSL_connect ... state=error: wrong version number`           | An `https` URL points at an OpenBao listener that serves `http`.   | Match the URL scheme to the listener. See [GitLab cannot connect to OpenBao](#gitlab-cannot-connect-to-openbao). |
| Rails or Sidekiq | `Retrying failed secrets_manager maintenance task`            | A provisioning or deprovisioning task is being retried.            | Check the worker error in the same log. Retries stop after three attempts. |

## Secrets Manager is stuck in provisioning

When you enable the Secrets Manager, the toggle can stay in a loading state with the status at
`provisioning`. The Secrets Manager has no `failed` state, so any step that fails before activation
leaves the record stuck. The usual cause is that Sidekiq cannot reach OpenBao.

To diagnose:

1. Check the Sidekiq logs for the provisioning worker:

   ```shell
   kubectl logs -n gitlab -l app=sidekiq -c sidekiq \
     | grep -E "ProvisionProjectSecretsManagerWorker|ProvisionGroupSecretsManagerWorker"
   ```

1. Test whether Sidekiq can reach OpenBao, from a Sidekiq pod or node:

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

A maintenance worker retries a stale task up to three times, then stops. After that, the record
stays in `provisioning` with no automated recovery, and the retries log `Retrying failed
secrets_manager maintenance task`.

After you fix the connectivity, disable and re-enable the Secrets Manager to provision it again.

### Authentication mount missing after self-initialization

On a fresh installation with multiple OpenBao pods, a self-initialization race can leave OpenBao
unsealed but without the `gitlab_rails_jwt/` authentication mount. The pods look healthy, but secret
operations fail with permission denied. Run `bao auth list` with a root token to confirm the mount
exists. To prevent the race, start a fresh installation with a single replica, confirm
initialization completes, then scale up.

## GitLab cannot connect to OpenBao

GitLab Rails and Sidekiq connect to OpenBao over HTTP. Rails uses `internal_url`, and falls back to
`url` when `internal_url` is not set. To inspect the configuration, run this in the
[Rails console](../operations/rails_console.md):

```ruby
Gitlab.config.openbao.to_h
```

Common causes:

- An `https://` URL against an OpenBao listener that serves `http` fails with
  `wrong version number`. `global.openbao.https` sets the scheme GitLab connects with, not the
  OpenBao listener TLS. The listener serves plain HTTP by default. Either leave
  `global.openbao.https` unset to match it, or enable listener TLS with
  `openbao.config.tlsDisable: false` and set `global.openbao.https` to `true`.
- OIDC discovery and audit logging fail over an untrusted TLS certificate. Use a certificate that
  GitLab trusts.
- A request that produces no OpenBao audit entry never reached the authentication backend. Check
  the Ingress or reverse proxy.

For a Cloud Native installation, a working configuration looks like this:

```yaml
global:
  openbao:
    enabled: true
    url: http://gitlab-openbao-active:8200
    internal_url: http://gitlab-openbao-active:8200
```

For a Linux package installation, GitLab uses the `gitlab_rails['openbao']['url']` setting in
`/etc/gitlab/gitlab.rb` to connect to OpenBao. The bundled NGINX reverse proxy routes to OpenBao
with the `oak['components']['openbao']` settings. For more information, see
[Install OpenBao for a Linux package deployment](linux_package_integration.md).

## JWT authentication fails

GitLab authenticates to OpenBao with a JWT. The `aud` (audience) claim in the JWT must exactly match
the `bound_audiences` value on the OpenBao authentication role. Any difference fails authentication,
including a trailing slash, `http` compared to `https`, or a port.

OpenBao stores `bound_audiences` at initialization time, derived from the OpenBao URL. The stored
value does not change when you later change the URL. Changing the URL therefore breaks
authentication, because the stored `bound_audiences` no longer matches the `aud` GitLab sends. To
set the audience independently of the connect URL, use `global.openbao.jwt_audience`.

To find the audience GitLab sends, run this in the Rails console:

```ruby
SecretsManagement::ProjectSecretsManager.jwt_audience
```

The method returns the configured `jwt_audience`, or the OpenBao `url` when `jwt_audience` is not
set. To inspect the stored value, read the authentication role with a root token and compare
`bound_audiences` to that audience.

> [!warning]
> You cannot fix this without privileged access. The root token is revoked after
> self-initialization, and the unseal key is not a substitute. The unseal secret contains only the
> unseal key, not a root token.

To fix the mismatch without deleting stored secrets, reconfigure authentication with a recovery
key. For the procedure, see
[Reconfigure authentication with a recovery key](maintenance.md#reconfigure-authentication-with-a-recovery-key).

If you do not have a recovery key, [reset OpenBao data](maintenance.md#reset-openbao-data). This
deletes all stored secrets.

## OpenBao pods are sealed

If `bao status` reports `Sealed    true` at startup, auto-unseal failed:

- With the default static unseal, the cause is usually a missing or incorrect unseal secret. The
  secret is `gitlab-openbao-unseal` for a Cloud Native installation, and `openbao-static-unseal` for
  a Linux package installation.
- With KMS auto-unseal, currently AWS KMS (`awskms`), the cause is usually that OpenBao cannot reach
  the KMS.

To check the seal status, see [Check OpenBao status](#check-openbao-status).

> [!warning]
> If you rotate the static unseal key without keeping the previous key available, OpenBao cannot
> decrypt existing data. Add the previous key alongside the new key, and remove it only after all
> pods run on the new key.

## Database problems

OpenBao requires its own PostgreSQL database. The GitLab chart fails the installation or upgrade if
you enable OpenBao without a dedicated database.

Other database problems:

- Connection pool exhaustion or high latency causes intermittent timeouts.
- Incorrect `md5_auth_cidr_addresses`, `sslMode`, or password values in a Linux package PostgreSQL
  configuration send the OpenBao pods into `CrashLoopBackOff`. For the correct settings, see
  [Install OpenBao for a Linux package deployment](linux_package_integration.md).

## Audit events are missing

OpenBao posts audit events to GitLab at `/api/v4/internal/secrets_manager/audit_logs`. The GitLab
chart enables audit logging by default. If audit events do not arrive:

- Setting `config.audit.http.enabled` to `false` stops OpenBao from posting events. Confirm that
  audit logging is enabled.
- A shared audit token mismatch returns `401` on the audit endpoint. Confirm that GitLab and
  OpenBao use the same audit token.

## Troubleshoot Geo deployments

OpenBao runs as an active node on the primary Geo site and as a standby node on each secondary site.
A secondary node connects to a read-only PostgreSQL replica, so it logs `failed to acquire lock` and
`cannot execute INSERT in a read-only transaction`. These messages are expected.

If a secondary node logs `cipher: message authentication failed` or `unknown key ID`, its seal key
does not match the primary. The fix depends on the seal mechanism:

- With a static unseal, copy the `gitlab-openbao-unseal` secret from the primary cluster to the
  secondary cluster, then restart the OpenBao pods:

  ```shell
  kubectl -n gitlab get secret gitlab-openbao-unseal -o yaml
  ```

- With a KMS seal, configure both sites to use the same KMS key.

If JWT authentication fails after a failover, the audience no longer matches the stored
`bound_audiences`. The fix depends on the domain:

- If both sites use the primary OpenBao URL, set `jwt_audience` to the primary OpenBao URL on both
  sites. See [Install OpenBao on a secondary site](_index.md#install-openbao-on-a-secondary-site).
- If the secondary site uses a different domain, this configuration is not supported. Reconfiguring
  the audience does not restore authentication, because every project and group namespace also needs
  re-provisioning. Update DNS so the primary domain points to the promoted secondary. For more
  information, see [Geo deployment](_index.md#geo-deployment).

## Diagnose slow secret operations

When CI/CD jobs are slow to fetch secrets, or secret operations time out, use the following queries
to find the cause.
Run these queries in the Prometheus or Grafana instance that scrapes the OpenBao metrics.
To expose those metrics, see [OpenBao metrics](_index.md#openbao-metrics).

### Confirm latency is elevated

Use the following query to measure average request latency in milliseconds. The query works at any
traffic level, including low-traffic deployments:

```prometheus
rate(openbao_core_handle_request_sum[5m])
/
rate(openbao_core_handle_request_count[5m])
```

Under normal load, average latency across all request types is typically 3 to 7 ms. Investigate if
average latency consistently exceeds 20 ms.

When OpenBao is actively processing requests, use the following query for P99 latency:

```prometheus
openbao_core_handle_request{quantile="0.99"}
```

Normal P99 is below 10 ms. This query returns `NaN` when OpenBao is idle because the summary window
has no recent observations. Use the rate-based query in that case.

### Identify potential issues

| Potential issue             | What to check                   | Query                                                                       | Threshold           | Action                                                             |
|-----------------------------|---------------------------------|-----------------------------------------------------------------------------|---------------------|--------------------------------------------------------------------|
| CPU limit too low           | CFS throttle ratio              | [CPU throttling query](_index.md#cpu-throttling)                            | > 25%               | Increase CPU limit                                                 |
| Demand exceeds CPU capacity | CPU utilization                 | [CPU utilization query](_index.md#cpu-utilization)                          | > 50% of request    | Scale to the next row in the [sizing table](_index.md#pod-resources) |
| Request surge               | In-flight requests              | `openbao_core_in_flight_requests`                                           | Sustained above 5   | Transient. Monitor for recurrence.                                 |
| PostgreSQL bottleneck       | Average PostgreSQL read latency | `rate(openbao_postgres_get_sum[5m]) / rate(openbao_postgres_get_count[5m])` | > 5 ms              | Check PostgreSQL resources and connection pool                     |
| Memory pressure             | Memory utilization              | [Memory utilization query](_index.md#memory-utilization)                    | Near memory request | Increase memory using the [namespace formula](_index.md#memory-utilization) |

If PostgreSQL latency is elevated, check whether the connection pool is saturated. If all
connections are busy, additional requests queue and cause latency. For connection pool
configuration, see [Database resources](_index.md#database-resources).
