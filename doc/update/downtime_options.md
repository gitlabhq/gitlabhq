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

## Upgrades with downtime

If you want to upgrade to more than one minor release at a time (for example, from 14.6 to 14.9), you must take your
GitLab instance offline and [upgrade with downtime](with_downtime.md). Before starting, consult the version-specific
upgrade notes relevant to your [upgrade path](upgrade_paths.md):

- [GitLab 17 upgrade notes](versions/gitlab_17_changes.md)
- [GitLab 16 upgrade notes](versions/gitlab_16_changes.md)
- [GitLab 15 upgrade notes](versions/gitlab_15_changes.md)

For upgrades with downtime for:

- Single node instances, you only [upgrade the Linux package](package/_index.md).
- Multi-node instances, the process for upgrading is the same as for zero-downtime upgrades. The differences relate to
  the servers running Rails (Puma/Sidekiq) and the order of events.

## Zero-downtime upgrades

With [zero-downtime upgrades](zero_downtime.md), you can upgrade a live GitLab environment without having to take it
offline.

To upgrade with zero downtime, upgrade GitLab nodes in a certain order, using a combination of load balancing,
HA systems, and graceful reloads to minimize the disruption.

The documentation only covers core GitLab components. For upgrades or management of third party services such as AWS RDS,
refer to their documentation.

{{< alert type="note" >}}

You cannot [upgrade a Helm chart instance](https://docs.gitlab.com/charts/installation/upgrade.html) with zero downtime.
Support is available with the [GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades.html) but there are
[known limitations](https://docs.gitlab.com/operator/#known-issues) with this deployment method.

{{< /alert >}}

### Before you start

Achieving zero downtime as part of an upgrade is notably difficult for any distributed application. The documentation
has been tested as given against our HA [reference architectures](../administration/reference_architectures/_index.md)
and resulted in effectively no observable downtime. But be aware your mileage may vary dependent on the specific system
makeup.

For additional confidence, some customers have found success with further techniques such as manually draining nodes by
using specific load balancer or infrastructure capabilities. These techniques depend greatly on the underlying
infrastructure capabilities.

For any additional information reach out to your GitLab representative or the
[Support team](https://about.gitlab.com/support/).

### Requirements

The zero-downtime upgrade process requires a multi-node GitLab environment built with the Linux package that has load
balancing and available HA mechanisms configured as follows:

- External load balancer configured for GitLab application nodes with health checks enabled against the
  [readiness](../administration/monitoring/health_check.md#readiness) (`/-/readiness`) endpoint.
- Internal load balancer configured for any PgBouncer and Praefect components with TCP health checks enabled.
- HA mechanisms configured for the Consul, Postgres, and Redis components if present.
  - Any of these components that are not deployed in a HA fashion must upgraded separately with downtime.
  - For databases, the [Linux package only supports HA for the main GitLab database](https://gitlab.com/groups/gitlab-org/-/epics/7814).
    For any other databases, such as the [Praefect database](zero_downtime.md#gitaly-cluster-praefect), a third party
    database solution is required to achieve HA and subsequently to avoid downtime.

For zero-downtime upgrades, you must:

- Upgrade **one minor release at a time**. So from `16.1` to `16.2`, not to `16.3`. If you skip releases, database
  modifications might be run in the wrong sequence
  [and leave the database schema in a broken state](https://gitlab.com/gitlab-org/gitlab/-/issues/321542).
- Use post-deployment migrations.

### Considerations

When considering a zero-downtime upgrade, be aware that:

- Most of the time, you can safely upgrade from a patch release to the next minor release if the patch release is not
  the latest. For example, upgrading from `16.3.2` to `16.4.1` should be safe even if `16.3.3` has been released. You
  should verify the version-specific upgrade notes relevant to your [upgrade path](upgrade_paths.md) and be
  aware of any required upgrade stops:
  - [GitLab 17 upgrade notes](versions/gitlab_17_changes.md)
  - [GitLab 16 upgrade notes](versions/gitlab_16_changes.md)
  - [GitLab 15 upgrade notes](versions/gitlab_15_changes.md)
- Some releases may include background migrations. These migrations are performed in the background by Sidekiq and are
  often used for migrating data. Background migrations are only added in the monthly releases.
  - Certain major or minor releases may require a set of background migrations to be finished. While this doesn't require
    downtime (if the previous conditions are met), you must wait for background migrations to complete between each major
    or minor release upgrade.
  - The time necessary to complete these migrations can be reduced by increasing the number of Sidekiq workers that can
    process jobs in the `background_migration` queue. To see the size of this queue,
    [check for background migrations before upgrading](background_migrations.md).
- Zero-downtime upgrades can be performed for [Gitaly](zero_downtime.md#gitaly) because of a graceful reload mechanism.
  The [Gitaly Cluster (Praefect)](zero_downtime.md#gitaly-cluster-praefect) component can also be directly upgraded without
  downtime. However, the Linux package does not offer HA or zero downtime support for the Praefect database. A third-party
  database solution is required to avoid downtime.
- [PostgreSQL major version upgrades](../administration/postgresql/replication_and_failover.md#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster)
  are a separate process and not covered by zero-downtime upgrades. Smaller upgrades are covered.
- Zero-downtime upgrades are supported for the noted GitLab components you've deployed with the Linux package. If you've
  deployed select components through a supported third party service, such as PostgreSQL in AWS RDS or Redis in GCP
  Memorystore, upgrades for those services must be performed separately as per their standard processes.
- As a general guideline, the larger amount of data you have, the more time is needed for the upgrade to complete. In
  testing, any database smaller than 10 GB shouldn't generally take longer than an hour, but your mileage may vary.

### Upgrade order

You should take a back-to-front approach for the order of what components to upgrade with zero downtime:

1. Stateful backends
1. Backend dependents
1. Frontends

Though you can change the order of deployment, you should deploy the components running GitLab application code
(for example, Rails and Sidekiq) together. If possible, upgrade the supporting infrastructure separately because these
components do not have dependencies on changes introduced in a version upgrade for a major release.

You should upgrade GitLab components in the following order:

1. Consul
1. PostgreSQL
1. PgBouncer
1. Redis
1. Gitaly
1. Praefect
1. Rails
1. Sidekiq
