---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project-level Kubernetes clusters (certificate-based) (deprecated)

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/35954) in GitLab 10.1.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)
in GitLab 14.5. To connect clusters to GitLab, use the
[GitLab agent](../../clusters/agent/index.md).

[Project-level](../../infrastructure/clusters/connect/index.md#cluster-levels-deprecated) Kubernetes clusters
allow you to connect a Kubernetes cluster to a project in GitLab.

You can also [connect multiple clusters](multiple_kubernetes_clusters.md)
to a single project.

## View your project-level clusters

To view project-level Kubernetes clusters:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Kubernetes clusters**.
