---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Connect a cluster to GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The [certificate-based Kubernetes integration with GitLab](../_index.md)
was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)
in GitLab 14.5. To connect your clusters, use the [GitLab agent](../../../clusters/agent/_index.md).

## Cluster levels (deprecated)

> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
The [concept of cluster levels was deprecated](../_index.md#cluster-levels)
in GitLab 14.5.

Choose your cluster's level according to its purpose:

| Level | Purpose |
|--|--|
| [Project level](../../../project/clusters/_index.md) | Use your cluster for a single project. |
| [Group level](../../../group/clusters/_index.md) | Use the same cluster across multiple projects within your group. |
| [Instance level](../../../instance/clusters/_index.md) | Use the same cluster across groups and projects within your instance. |

### View your clusters

To view the Kubernetes clusters connected to your project,
group, or instance, open the cluster's page according to
your cluster's level.

**Project-level clusters:**

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Kubernetes clusters**.

**Group-level clusters:**

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Operate > Kubernetes clusters**.

**Instance-level clusters:**

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Kubernetes**.

## Security implications for clusters connected with certificates

> - Connecting clusters to GitLab through cluster certificates was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
The whole cluster security is based on a model where [developers](../../../permissions.md)
are trusted, so **only trusted users should be allowed to control your clusters**.

The use of cluster certificates to connect your cluster grants
access to a wide set of functionalities needed to successfully
build and deploy a containerized application. Bear in mind that
the same credentials are used for all the applications running
on the cluster.
