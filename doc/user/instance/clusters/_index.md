---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Instance Kubernetes clusters (certificate-based) (deprecated)
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5. To connect clusters to GitLab,
use the [GitLab agent for Kubernetes](../../clusters/agent/_index.md).

{{< /alert >}}

Similar to Kubernetes clusters for [projects](../../project/clusters/_index.md)
and [groups](../../group/clusters/_index.md), instance Kubernetes clusters enable
you to connect a Kubernetes cluster to the GitLab instance, and use the same cluster
across multiple projects.

To view Kubernetes clusters for your instance:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Kubernetes**.

## Cluster precedence

GitLab tries to match clusters in the following order:

- Project clusters.
- Group clusters.
- Instance clusters.

To be selected, the cluster must be enabled and
match the [environment selector](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).

## Cluster environments

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

For a consolidated view of which CI [environments](../../../ci/environments/_index.md)
are deployed to the Kubernetes cluster, see the documentation for
[cluster environments](../../clusters/environments.md).

## More information

For information on integrating GitLab and Kubernetes, see
[Kubernetes clusters](../../infrastructure/clusters/_index.md).
