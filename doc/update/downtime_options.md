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

Downtime options during an upgrade depend on your instance type:

- Single-node instance: You must upgrade with downtime. Users see
  a **Deploy in progress** message or a `502` error.
- Multi-node instance: Choose between upgrading with or without downtime.

To upgrade across multiple minor releases (for example, 14.6 to 14.9), you must
take your GitLab instance offline and upgrade with downtime.

## Upgrades with downtime

Before starting, review the version-specific upgrade notes for your
[upgrade path](upgrade_paths.md):

- [GitLab 17 upgrade notes](versions/gitlab_17_changes.md)
- [GitLab 16 upgrade notes](versions/gitlab_16_changes.md)
- [GitLab 15 upgrade notes](versions/gitlab_15_changes.md)

For single-node instances, see [upgrade Linux package instances](package/_index.md).
For multi-node instances, see [upgrade a multi-node instance with downtime](with_downtime.md).

## Zero-downtime upgrades

Zero-downtime upgrades let you upgrade a live GitLab environment without
taking it offline.

{{< alert type="note" >}}

You cannot [upgrade a Helm chart instance](https://docs.gitlab.com/charts/installation/upgrade.html)
with zero downtime. Support is available with the [GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades.html)
but there are [known limitations](https://docs.gitlab.com/operator/#known-issues).

{{< /alert >}}

For zero downtime, upgrade GitLab nodes in a specific order. Use load balancing,
HA systems, and graceful reloads to minimize disruption.

The documentation covers only core GitLab components. For upgrades or management
of third-party services such as AWS RDS, see their documentation.

To upgrade a multi-node instance without downtime, see [zero-downtime upgrades](zero_downtime.md).
