---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project-level Kubernetes clusters with cluster certificates (DEPRECATED) **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/35954) in GitLab 10.1.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
Project-level Kubernetes clusters with cluster certificates was
[deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)
in GitLab 14.5.
To connect your cluster to GitLab, use the [GitLab Kubernetes Agent](../../../user/clusters/agent/index.md).

[Project-level Kubernetes clusters](../../infrastructure/clusters/connect/index.md#cluster-levels)
allow you to connect a Kubernetes cluster to a project in GitLab.

You can also [connect multiple clusters](multiple_kubernetes_clusters.md)
to a single project.

After connecting a cluster to GitLab, you can benefit from the large number of
[GitLab features available for Kubernetes clusters](../../infrastructure/clusters/index.md) to manage and deploy to your cluster.

## View your project-level clusters

To view project-level Kubernetes clusters:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
