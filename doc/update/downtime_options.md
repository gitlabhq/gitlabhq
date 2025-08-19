---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Consider upgrade downtime options
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Options available for downtime during an upgrade depend on the type of instance you have:

- Single node instance: GitLab is not available to users while an upgrade is in progress. The user's web browser shows
  a **Deploy in progress** message or a `502` error.
- Multi-node instance: You can choose to upgrade with or without downtime for users.

## Zero downtime upgrades

With zero-downtime upgrades, it's possible to upgrade a live GitLab environment without having to
take it offline. This guide will take you through the core process of performing
such an upgrade.

At a high level, this process is done by sequentially upgrading GitLab nodes in a certain order, utilizing a combination of
Load Balancing, HA systems and graceful reloads to minimize the disruption.

For the purposes of this guide it will only pertain to the core GitLab components where applicable. For upgrades
or management of third party services, such as AWS RDS, refer to the respective documentation.

### Before you start

Achieving true zero downtime as part of an upgrade is notably difficult for any distributed application. The process detailed in
this guide has been tested as given against our HA [Reference Architectures](../administration/reference_architectures/_index.md)
and was found to result in effectively no observable downtime, but be aware your mileage may vary dependent on the specific system makeup.

For additional confidence, some customers have found success with further techniques such as the
manually draining nodes by using specific load balancer or infrastructure capabilities. These techniques depend greatly
on the underlying infrastructure capabilities and as a result are not covered in this guide.
For any additional information reach out to your GitLab representative
or the [Support team](https://about.gitlab.com/support/).

### Requirements and considerations

The zero-downtime upgrade process has the following requirements:

- Zero-downtime upgrades are only supported on multi-node GitLab environments built with the Linux package that have Load Balancing and available HA mechanisms configured as follows:
  - External Load Balancer configured for Rails nodes with health checks enabled against the [Readiness](../administration/monitoring/health_check.md#readiness) (`/-/readiness`) endpoint.
  - Internal Load Balancer configured for any PgBouncer and Praefect components with TCP health checks enabled.
  - HA mechanisms configured for the Consul, Postgres, Redis components if present.
    - Any of these components that are not deployed in a HA fashion need to be upgraded separately with downtime.
    - For databases, the [Linux package only supports HA for the main GitLab database](https://gitlab.com/groups/gitlab-org/-/epics/7814). For any other databases, such as the [Praefect database](zero_downtime.md#gitaly-cluster-praefect), a third party database solution is required to achieve HA and subsequently to avoid downtime.
- **You can only upgrade one minor release at a time**. So from `16.1` to `16.2`, not to `16.3`. If you skip releases, database modifications may be run in the wrong sequence [and leave the database schema in a broken state](https://gitlab.com/gitlab-org/gitlab/-/issues/321542).
- You have to use post-deployment migrations.
- [Zero-downtime upgrades are not available with the GitLab Charts](https://docs.gitlab.com/charts/installation/upgrade.html). Support is available with the [GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades.html) but there are [known limitations](https://docs.gitlab.com/operator/#known-issues) with this deployment method and as such it's not covered in this guide at this time.

In addition to the previous, be aware of the following considerations:

- Most of the time, you can safely upgrade from a patch release to the next minor release if the patch release is not the latest.
  For example, upgrading from `16.3.2` to `16.4.1` should be safe even if `16.3.3` has been released. You should verify the
  version-specific upgrading instructions relevant to your [upgrade path](upgrade_paths.md) and be aware of any required upgrade stops:
  - [GitLab 17 changes](versions/gitlab_17_changes.md)
  - [GitLab 16 changes](versions/gitlab_16_changes.md)
  - [GitLab 15 changes](versions/gitlab_15_changes.md)
- Some releases may include [background migrations](background_migrations.md). These migrations are performed in the background by Sidekiq and are often used for migrating data. Background migrations are only added in the monthly releases.
  - Certain major or minor releases may require a set of background migrations to be finished. While this doesn't require downtime (if the previous conditions are met), it's required that you [wait for background migrations to complete](background_migrations.md) between each major or minor release upgrade.
  - The time necessary to complete these migrations can be reduced by increasing the number of Sidekiq workers that can process jobs in the
    `background_migration` queue. To see the size of this queue, [check for background migrations before upgrading](background_migrations.md).
- Zero downtime upgrades can be performed for [Gitaly](zero_downtime.md#gitaly) when it's set up in its Cluster or Sharded setups due to a graceful reload mechanism. For the [Gitaly Cluster (Praefect)](zero_downtime.md#gitaly-cluster-praefect) component it can also be directly upgraded without downtime, however the GitLab Linux package does not offer HA and subsequently Zero Downtime support for it's database - A third party database solution is required to avoid downtime.
- [PostgreSQL major version upgrades](../administration/postgresql/replication_and_failover.md#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster) are a separate process and not covered by zero-downtime upgrades (smaller upgrades are covered).
- Zero-downtime upgrades are supported for the noted GitLab components you've deployed with the GitLab Linux package. If you've deployed select components through a supported third party service, such as PostgreSQL in AWS RDS or Redis in GCP Memorystore, upgrades for those services need to be performed separately as per their standard processes.
- As a general guideline, the larger amount of data you have, the more time is needed for the upgrade to complete. In testing, any database smaller than 10 GB shouldn't generally take longer than an hour, but your mileage may vary.

{{< alert type="note" >}}

If you want to upgrade multiple releases or do not meet these requirements [upgrades with downtime](with_downtime.md) should be explored instead.

{{< /alert >}}

### Upgrade order

We recommend a "back to front" approach for the order of what components to upgrade with zero downtime.
Generally this would be stateful backends first, their dependents next and then the frontends accordingly.
While the order of deployment can be changed, it is best to deploy the components running GitLab application code (Rails, Sidekiq) together. If possible, upgrade the supporting infrastructure (PostgreSQL, PgBouncer, Consul, Gitaly, Praefect, Redis) separately because these components do not have dependencies on changes introduced in a version update within a major release.
As such, we generally recommend the following order:

1. Consul
1. PostgreSQL
1. PgBouncer
1. Redis
1. Gitaly
1. Praefect
1. Rails
1. Sidekiq

## Upgrades with downtime

While you can upgrade a multi-node GitLab deployment [with zero downtime](zero_downtime.md),
there are a number of constraints. In particular, you can upgrade to only one minor release
at a time, for example, from 14.6 to 14.7, then to 14.8, etc.

If you want to upgrade to more than one minor release at a time (for example, from 14.6 to 14.9),
you must take your GitLab instance offline, which implies downtime.
Before starting this process, verify the version-specific upgrading instructions relevant to your [upgrade path](upgrade_paths.md):

- [GitLab 17 changes](versions/gitlab_17_changes.md)
- [GitLab 16 changes](versions/gitlab_16_changes.md)
- [GitLab 15 changes](versions/gitlab_15_changes.md)

For a single node installation, you must only [upgrade the GitLab package](package/_index.md).

The process for upgrading a number of components of a multi-node GitLab
installation is the same as for zero-downtime upgrades.
The differences relate to the servers running Rails (Puma/Sidekiq) and
the order of events.
