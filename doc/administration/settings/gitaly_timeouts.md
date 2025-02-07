---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly timeouts
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

[Gitaly](../gitaly/_index.md) provides two types of configurable timeouts:

- Call timeouts, configured by using the GitLab UI.
- Negotiation timeouts, configured by using Gitaly configuration files.

## Configure the call timeouts

Configure the following call timeouts to make sure that long-running Gitaly calls don't needlessly take up resources. To
configure the call timeouts:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand the **Gitaly timeouts** section.
1. Set each timeout as required.

### Available call timeouts

Different call timeouts are available for different Gitaly operations.

| Timeout | Default    | Description |
|:--------|:-----------|:------------|
| Default | 55 seconds | Timeout for most Gitaly calls (not enforced for `git` `fetch` and `push` operations, or Sidekiq jobs). For example, checking if a repository exists on disk. Makes sure that Gitaly calls made in a web request cannot exceed the entire request timeout. It should be shorter than the [worker timeout](../operations/puma.md#change-the-worker-timeout) that can be configured for [Puma](../../install/requirements.md#puma). If a Gitaly call timeout exceeds the worker timeout, the remaining time from the worker timeout is used to avoid having to terminate the worker. |
| Fast    | 10 seconds | Timeout for fast Gitaly operations used in requests, sometimes multiple times. For example, checking if a repository exists on disk. If fast operations exceed this threshold, there may be a problem with a storage shard. Failing fast can help maintain the stability of the GitLab instance. |
| Medium  | 30 seconds | Timeout for Gitaly operations that should be fast (possibly in requests) but preferably not used multiple times in a request. For example, loading blobs. Timeout that should be set between Default and Fast. |

## Configure the negotiation timeouts

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/5574) in GitLab 16.5.

You might need to increase the negotiation timeout:

- For particularly large repositories.
- When performing these commands in parallel.

You can configure negotiation timeouts for:

- `git-upload-pack(1)`, which is invoked by a Gitaly node when you execute `git fetch`.
- `git-upload-archive(1)`, which is invoked by a Gitaly node when you execute `git archive --remote`.

To configure these timeouts:

::Tabs

:::TabTitle Linux package (Omnibus)

Edit `/etc/gitlab/gitlab.rb`:

```ruby
gitaly['configuration'] = {
    timeout: {
        upload_pack_negotiation: '10m',      # 10 minutes
        upload_archive_negotiation: '20m',   # 20 minutes
    }
}
```

:::TabTitle Self-compiled (source)

Edit `/home/git/gitaly/config.toml`:

```toml
[timeout]
upload_pack_negotiation = "10m"
upload_archive_negotiation = "20m"
```

::EndTabs

For the values, use the format of [`ParseDuration`](https://pkg.go.dev/time#ParseDuration) in Go.

These timeouts affect only the [negotiation phase](https://git-scm.com/docs/pack-protocol/2.2.3#_packfile_negotiation) of
remote Git operations, not the entire transfer.
