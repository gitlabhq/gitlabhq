---
type: index
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Configuring Redis for scaling **(FREE SELF)**

Based on your infrastructure setup and how you have installed GitLab, there are
multiple ways to configure Redis.

You can choose to install and manage Redis and Sentinel yourself, use a hosted
cloud solution, or you can use the ones that come bundled with the Omnibus GitLab
packages so you only need to focus on configuration. Pick the one that suits your needs.

## Redis replication and failover using Omnibus GitLab

This setup is for when you have installed GitLab using the
[Omnibus GitLab **Enterprise Edition** (EE) package](https://about.gitlab.com/install/?version=ee).

Both Redis and Sentinel are bundled in the package, so you can it to set up the whole
Redis infrastructure (primary, replica and sentinel).

[> Read how to set up Redis replication and failover using Omnibus GitLab](replication_and_failover.md)

## Redis replication and failover using the non-bundled Redis

This setup is for when you have installed GitLab using the
[Omnibus GitLab packages](https://about.gitlab.com/install/) (CE or EE),
or installed it [from source](../../install/installation.md), but you want to use
your own external Redis and sentinel servers.

[> Read how to set up Redis replication and failover using the non-bundled Redis](replication_and_failover_external.md)

## Standalone Redis using Omnibus GitLab

This setup is for when you have installed the
[Omnibus GitLab **Community Edition** (CE) package](https://about.gitlab.com/install/?version=ce)
to use the bundled Redis, so you can use the package with only the Redis service enabled.

[> Read how to set up a standalone Redis instance using Omnibus GitLab](standalone.md)
