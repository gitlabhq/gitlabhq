---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly timeouts and retries
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

[Gitaly](../gitaly/_index.md) provides two types of configurable timeouts:

- Call timeouts, configured by using the GitLab UI.
- Negotiation timeouts, configured by using Gitaly configuration files.

## Configure the call timeouts

Configure the following call timeouts to make sure that long-running Gitaly calls don't needlessly take up resources.

Prerequisites:

- Administrator access.

To configure the call timeouts:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Preferences**.
1. Expand the **Gitaly timeouts** section.
1. Set each timeout as required.

### Available call timeouts

Different call timeouts are available for different Gitaly operations.

| Timeout | Default    | Description |
|:--------|:-----------|:------------|
| Default | 55 seconds | Timeout for most Gitaly calls (not enforced for `git` `fetch` and `push` operations, or Sidekiq jobs). For example, checking if a repository exists on disk. Makes sure that Gitaly calls made in a web request cannot exceed the entire request timeout. It should be shorter than the [worker timeout](../operations/puma.md#change-the-worker-timeout) that can be configured for [Puma](../../install/requirements.md#puma). If a Gitaly call timeout exceeds the worker timeout, the remaining time from the worker timeout is used to avoid having to terminate the worker. |
| Fast    | 10 seconds | Timeout for fast Gitaly operations used in requests, sometimes multiple times. For example, checking if a repository exists on disk. If fast operations exceed this threshold, there may be a problem with a storage shard. Failing fast can help maintain the stability of the GitLab instance. |
| Medium  | 30 seconds | Timeout for Gitaly operations that should be fast (possibly in requests) but preferably not used multiple times in a request. For example, loading blobs. Timeout that should be set between Default and Fast. |

By default, the **Default** timeout cannot be set higher than `57` seconds. For more information, see [Unable to raise Gitaly default timeout above 57 seconds](#unable-to-raise-gitaly-default-timeout-above-57-seconds).

## Configure the negotiation timeouts

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/5574) in GitLab 16.5.

{{< /history >}}

You might need to increase the negotiation timeout:

- For particularly large repositories.
- When performing these commands in parallel.

You can configure negotiation timeouts for:

- `git-upload-pack(1)`, which is invoked by a Gitaly node when you execute `git fetch`.
- `git-upload-archive(1)`, which is invoked by a Gitaly node when you execute `git archive --remote`.

To configure these timeouts:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Edit `/etc/gitlab/gitlab.rb`:

```ruby
gitaly['configuration'] = {
    timeout: {
        upload_pack_negotiation: '10m',      # 10 minutes
        upload_archive_negotiation: '20m',   # 20 minutes
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Edit `/home/git/gitaly/config.toml`:

```toml
[timeout]
upload_pack_negotiation = "10m"
upload_archive_negotiation = "20m"
```

{{< /tab >}}

{{< /tabs >}}

For the values, use the format of [`ParseDuration`](https://pkg.go.dev/time#ParseDuration) in Go.

These timeouts affect only the [negotiation phase](https://git-scm.com/docs/pack-protocol/2.2.3#_packfile_negotiation) of
remote Git operations, not the entire transfer.

## Gitaly client retries

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/work_items/811) in GitLab 18.10.

{{< /history >}}

Gitaly can sometimes be briefly unavailable. For example, during GitLab upgrades. Especially with Gitaly on Kubernetes,
where a Pod starts and restarts take a couple of seconds.

To prevent GitLab from returning errors to clients when briefly unavailable, configure Gitaly client retries. When
Gitaly client retries are configured and Gitaly is unavailable, Gitaly client such as Rails (GitLab application),
Workhorse, and GitLab Shell retry request in an exponential backoff fashion.

Two parameters can be configured:

- `max_attempts`: Maximum number of retry attempts between 2 and 5.
- `max_backoff`: Maximum amount of time before the client stops retrying. Value must be a duration string, such as
  `1.4s` or `10s`.

The backoff multiplier is set to `2` and the initial backoff is derived from the two parameters.

### Configuration guidelines

The right configuration depends on your GitLab instance setup and how long Gitaly remains unavailable when such an event
occurs:

- On Kubernetes, a Gitaly Pod can take approximately 10 to 12 seconds to start, depending on the Cloud provider. The
  time includes how long it takes for the volume to be attached and mounted on the Pod.
- For Linux package instances, Gitaly might restart much faster because restarting Gitaly is a process restart.

Also keep in mind is that Gitaly can be configured with a graceful shutdown timeout. When Gitaly is shutting down, new
requests are rejected but the gRPC server keeps processing in-flight requests until either:

- They are all served.
- The shutdown timeout lapses.

This graceful shutdown timeout can play a role in how long Gitaly remains unavailable for new requests.

You should configure client retry with a `max_backoff` that is equal to or greater than sum of the graceful shutdown +
the (re)start time.

### Configure client retries

The following configuration applies to Rails (GitLab application), Workhorse, and GitLab Shell and the same
configuration applies to all clients.

Provided values are examples and should not be treated as guidelines.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Update your `gitlab.rb` file with these configurations:

```ruby
gitlab_rails['gitaly_client_max_attempts'] = 5
gitlab_rails['gitaly_client_max_backoff'] = '1.4s'
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Update your `values.yml` file with these configurations:

```yaml
global:
  gitaly:
    client:
      maxAttempts: 5
      maxBackoff: '1.4s'
```

{{< /tab >}}

{{< /tabs >}}

## Troubleshooting

When working with Gitaly timeouts, you might encounter the following issues.

### Unable to raise Gitaly default timeout above 57 seconds

> [!warning]
> Raise these values only when needed. A higher worker timeout means slow or stuck requests hold a Puma worker longer,
> reducing instance capacity. Common reasons to raise the Gitaly **Default** timeout include very large repositories on
> slow storage, expensive diff or compare views, or degraded Gitaly Cluster nodes. For background work such as imports,
> mirrors, or housekeeping, prefer offloading to Sidekiq, which is not bound by this cap.

By default, the [**Default** timeout](#available-call-timeouts) cannot be raised above `57` seconds.
Attempting to set the timeout higher produces the validation error:

```plaintext
Gitaly timeout default must be less than or equal to 57
```

This limit is imposed by three interacting timeouts:

- `puma['worker_timeout']`: Per-worker Puma timeout. Default is `60` seconds. For more information,
  see [change the worker timeout](../operations/puma.md#change-the-worker-timeout).
- `gitlab_rails['max_request_duration_seconds']`#GitLab application setting that limits the Gitaly
  **Default** timeout. Defaults is `(worker_timeout * 0.95).ceil` = `57` seconds. This setting must be
  strictly less than `puma['worker_timeout']`.
- `GITLAB_RAILS_RACK_TIMEOUT`: `Rack::Timeout` middleware `service_timeout`. Default is `60` seconds.
  This timeout is independent of the other two and it terminates the request at this value regardless
  of how the others are configured.

To raise the Gitaly **Default** timeout above 57 seconds, all three values must be raised together. For
example, to allow a Gitaly **Default** timeout of `110` seconds:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   puma['worker_timeout'] = 120
   gitlab_rails['max_request_duration_seconds'] = 114
   gitlab_rails['env'] = {
     'GITLAB_RAILS_RACK_TIMEOUT' => 120
   }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Preferences**.
1. Expand **Gitaly timeouts**.
1. Set **Default timeout** to the new desired value (up to `max_request_duration_seconds`).

   Leaving a small headroom is recommended. The built-in default uses a 5% gap
   (`max_request_duration_seconds = (worker_timeout * 0.95).ceil`), so the Rails request deadline trips before Puma
   reaches its worker timeout.

   `GITLAB_RAILS_RACK_TIMEOUT` does **not** raise the Gitaly cap on its own.
   `Settings.gitlab.max_request_duration_seconds` is what the application settings validator consults, and that is set
   by `gitlab_rails['max_request_duration_seconds']`. However, leaving `GITLAB_RAILS_RACK_TIMEOUT` at its default of
   `60` causes the Rack middleware to terminate any request longer than 60 seconds, including long Gitaly calls, before
   they can complete.
