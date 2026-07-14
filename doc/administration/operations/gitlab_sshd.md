---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure a lightweight alternative to OpenSSH for your GitLab instance.
title: '`gitlab-sshd`'
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

`gitlab-sshd` is [a standalone SSH server](https://gitlab.com/gitlab-org/gitlab-shell/-/tree/main/internal/sshd)
written in Go. It is a lightweight alternative to OpenSSH. It is part of the `gitlab-shell` package and
handles [SSH operations](https://gitlab.com/gitlab-org/gitlab-shell/-/blob/71a7f34a476f778e62f8fe7a453d632d395eaf8f/doc/features.md).

While OpenSSH uses a restricted shell approach, `gitlab-sshd`:

- Functions as a modern multi-threaded server application.
- Uses Remote Procedure Calls (RPCs) instead of the SSH transport protocol.
- Uses less memory than OpenSSH.
- Supports [group access restriction by IP address](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address)
  for applications running behind a proxy.

For more details about the implementation, see [the blog post](https://about.gitlab.com/blog/why-we-have-implemented-our-own-sshd-solution-on-gitlab-sass/).

If you are considering switching from OpenSSH to `gitlab-sshd`, consider:

- PROXY protocol: `gitlab-sshd` supports the PROXY protocol, allowing it to run behind proxy
  servers like HAProxy. This feature is not enabled by default but [can be enabled](#proxy-protocol-support).
- SSH certificates: `gitlab-sshd` supports instance-level SSH certificate authentication
  by using trusted CA keys configured in `config.yml`. For more information, see
  [Instance-level SSH certificates with `gitlab-sshd`](gitlab_sshd_ssh_certificates.md).
- 2FA recovery codes: `gitlab-sshd` does not support 2FA recovery code regeneration.
  Attempting to run `2fa_recovery_codes` results in the error:
  `remote: ERROR: Unknown command: 2fa_recovery_codes`. See
  [the discussion](https://gitlab.com/gitlab-org/gitlab-shell/-/issues/766#note_1906707753) for details.

The capabilities of GitLab Shell extend beyond Git operations and can be used for various
SSH-based interactions with GitLab.

## Enable `gitlab-sshd`

To use `gitlab-sshd`:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

The following instructions enable `gitlab-sshd` on a different port than OpenSSH:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_sshd['enable'] = true
   gitlab_sshd['listen_address'] = '[::]:2222' # Adjust the port accordingly
   ```

1. Optional. By default, Linux package installations generate SSH host keys for `gitlab-sshd` if
   they do not exist in `/var/opt/gitlab/gitlab-sshd`. If you wish to disable this automatic generation, add this line:

   ```ruby
   gitlab_sshd['generate_host_keys'] = false
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

By default, `gitlab-sshd` runs as the `git` user. As a result, `gitlab-sshd` cannot
run on privileged port numbers lower than 1024. This means users must
access Git with the `gitlab-sshd` port, or use a load balancer that
directs SSH traffic to the `gitlab-sshd` port to hide this.

Users may see host key warnings because the newly-generated host keys
differ from the OpenSSH host keys. Consider disabling host key
generation and copy the existing OpenSSH host keys into
`/var/opt/gitlab/gitlab-sshd` if this is an issue.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

The following instructions switch OpenSSH in favor of `gitlab-sshd`:

1. Set the `gitlab-shell` charts `sshDaemon` option to
   [`gitlab-sshd`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options).
   For example:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
   ```

1. Perform a Helm upgrade.

By default, `gitlab-sshd` listens for:

- External requests on port 22 (`global.shell.port`).
- Internal requests on port 2222 (`gitlab.gitlab-shell.service.internalPort`).

You can [configure different ports in the Helm chart](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#configuration).

{{< /tab >}}

{{< /tabs >}}

## Metrics

`gitlab-sshd` exposes [Prometheus metrics](../monitoring/prometheus/gitlab_metrics.md) on the monitoring endpoint
configured with `web_listen` in the `gitlab-shell` configuration.
`gitlab-sshd` serves the metrics at the `/metrics` path of that address.

| Metric                                                   | Type      | Description |
|:---------------------------------------------------------|:----------|:------------|
| `gitlab_shell_sshd_in_flight_connections`                | Gauge     | Connections currently being served by `gitlab-sshd`. |
| `gitlab_shell_sshd_concurrent_limited_sessions_total`    | Counter   | Number of times the concurrent sessions limit was hit. |
| `gitlab_shell_sshd_session_duration_seconds`             | Histogram | Duration of SSH sessions served by `gitlab-sshd`. |
| `gitlab_shell_sshd_session_established_duration_seconds` | Histogram | Latency until an SSH session is established, used as the latency for the `gitlab_sshd` service Apdex. |
| `gitlab_sli:shell_sshd_sessions:total`                   | Counter   | Number of SSH sessions that have been established (post-authentication session channels). |
| `gitlab_sli:shell_sshd_sessions:errors_total`            | Counter   | Number of SSH sessions that have failed. |
| `gitlab_sli:shell_sshd_connections:total`                | Counter   | Number of SSH connections that reached authentication. |
| `gitlab_sli:shell_sshd_connections:errors_total`         | Counter   | Number of SSH connections that failed due to a server-side error. |

### Session-level and connection-level SLIs

`gitlab-sshd` exposes two sets of Service Level Indicator (SLI) counters for SSH reliability:

- Session-level (`gitlab_sli:shell_sshd_sessions:*`) counts post-authentication session
  channels.
  This counter does not observe failures that occur during the authentication phase.
- Connection-level (`gitlab_sli:shell_sshd_connections:*`) counts each connection that
  reaches the authentication phase, and treats server-side errors during either the
  authentication or session phase as failures.
  Unlike the session-level counters, connection-level counters capture authentication-phase
  failures such as `authorized_keys` lookup errors.
  The connection-level counters exclude connections that never get past the transport handshake,
  such as port scanners and health checks.

The connection-level counters provide broader coverage of user-facing failures and are the
preferred signal for SSH reliability monitoring.

### Other GitLab Shell metrics

`gitlab-sshd` also exposes metrics for the interactions that GitLab Shell has with other
services.
These metrics are part of GitLab Shell's general instrumentation, and are not specific to the SSH
daemon.
The metrics cover connections to Gitaly, the GitLab internal API, Git LFS, and the Topology
Service.
When `gitlab-sshd` handles an SSH connection, `gitlab-sshd` runs these operations in its own
process and exposes the resulting counters on the same `/metrics` endpoint as the SSH metrics.
When you use OpenSSH instead of `gitlab-sshd`, GitLab Shell runs as a short-lived process for each
connection.
These short-lived processes increment the same counters, but do not expose a metrics endpoint, so
the counters are not available for scraping.

| Metric                                           | Type      | Description |
|:-------------------------------------------------|:----------|:------------|
| `gitlab_shell_gitaly_connections_total`          | Counter   | Number of Gitaly connections that have been established, labeled by `status` (`ok` or `fail`). |
| `gitlab_shell_http_requests_total`               | Counter   | Number of requests to the GitLab internal API, labeled by `code` and `method`. |
| `gitlab_shell_http_request_duration_seconds`     | Histogram | Latency of requests to the GitLab internal API, labeled by `code` and `method`. |
| `gitlab_shell_http_in_flight_requests`           | Gauge     | Requests to the GitLab internal API currently being performed. |
| `lfs_http_connections_total`                     | Counter   | Number of Git LFS-over-HTTP connections that have been established. |
| `lfs_ssh_connections_total`                      | Counter   | Number of Git LFS-over-SSH connections that have been established. |
| `gitlab_shell_topology_connections_total`        | Counter   | Number of Topology Service connections that have been established, labeled by `status` (`ok` or `fail`). |
| `gitlab_shell_topology_requests_total`           | Counter   | Number of Topology Service `Classify` requests, labeled by `status` (`ok` or `fail`). |
| `gitlab_shell_topology_request_duration_seconds` | Histogram | Latency of Topology Service `Classify` requests. |

## PROXY protocol support

Load balancers in front of `gitlab-sshd` cause GitLab to report the proxy IP address instead of the
client IP address. To obtain the real IP address, `gitlab-sshd` supports the
[PROXY protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

To enable the PROXY protocol:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_sshd['proxy_protocol'] = true
   # Proxy protocol policy ("use", "require", "reject", "ignore"), "use" is the default value
   gitlab_sshd['proxy_policy'] = "use"
   ```

   For more information about the `gitlab_sshd['proxy_policy']` options, see the
   [`go-proxyproto` library](https://github.com/pires/go-proxyproto/blob/4ba2eb817d7a57a4aafdbd3b82ef0410806b533d/policy.go#L20-L35).

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Set the [`gitlab.gitlab-shell.config` options](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#installation-command-line-options). For example:

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         proxyProtocol: true
         proxyPolicy: "use"
   ```

1. Perform a Helm upgrade.

{{< /tab >}}

{{< /tabs >}}
