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
