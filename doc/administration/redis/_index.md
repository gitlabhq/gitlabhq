---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configuring Redis for scaling
description: Configure Redis for scaling.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Based on your infrastructure setup and how you have installed GitLab, there are
multiple ways to configure Redis.

You can choose to install and manage Redis and Sentinel yourself, use a hosted
cloud solution, or you can use the ones that come bundled with the Linux
packages so you can only focus on configuration. Pick the one that suits your needs.

## Use Valkey instead of Redis

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113) in GitLab 18.9 as a [beta](../../policy/development_stages_support.md#beta).

{{< /history >}}

[Valkey](https://valkey.io/) is an open source high-performance key/value datastore that is
fully compatible with Redis. GitLab supports Valkey as an opt-in alternative to Redis.

Using Valkey instead of Redis is a [beta](../../policy/development_stages_support.md#beta) feature.

When enabled, Valkey uses the same user, group, data directory, and log directory conventions
as Redis by default.

To switch to Valkey on Redis nodes, add the following to `/etc/gitlab/gitlab.rb`:

```ruby
redis['backend'] = 'valkey'
```

## Redis replication and failover using the Linux package

This setup is for when you have installed GitLab using the
[Linux **Enterprise Edition** (EE) package](https://about.gitlab.com/install/?version=ee).

Both Redis and Sentinel are bundled in the package, so you can use it to set up the whole Redis infrastructure (primary,
replica and sentinel).

For more information, see [Redis replication and failover with the Linux package](replication_and_failover.md).

## Redis replication and failover using the non-bundled Redis

This setup is for when you have either a [Linux package](https://about.gitlab.com/install/) installation or a
[self-compiled installation](../../install/self_compiled/_index.md), but you want to use your own external Redis and Sentinel
servers.

For more information, see [Redis replication and failover providing your own instance](replication_and_failover_external.md).

## Standalone Redis using the Linux package

This setup is for when you have installed the
[Linux **Community Edition** (CE) package](https://about.gitlab.com/install/?version=ce)
to use the bundled Redis, so you can use the package with only the Redis service enabled.

For more information, see [Standalone Redis using the Linux package](standalone.md).
