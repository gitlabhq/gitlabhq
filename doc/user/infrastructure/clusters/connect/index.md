---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Connect a cluster to GitLab **(FREE)**

The [certificate-based Kubernetes integration with GitLab](../index.md)
was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)
in GitLab 14.5. To connect your clusters, use the [GitLab Agent](../../../clusters/agent/index.md).

<!-- TBA: (We need to resolve https://gitlab.com/gitlab-org/gitlab/-/issues/343660 before adding this line)
If you don't have a cluster yet, create one and connect it to GitLab through the Agent.
You can also create a new cluster from GitLab using [Infrastructure as Code](../../iac/index.md#create-a-new-cluster-through-iac).
-->

## Cluster levels (DEPRECATED)

> [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
The [concept of cluster levels was deprecated](../index.md#cluster-levels)
in GitLab 14.5.

Choose your cluster's level according to its purpose:

| Level | Purpose |
|--|--|
| [Project level](../../../project/clusters/index.md) | Use your cluster for a single project. |
| [Group level](../../../group/clusters/index.md) | Use the same cluster across multiple projects within your group. |
| [Instance level](../../../instance/clusters/index.md) | Use the same cluster across groups and projects within your instance. |

### View your clusters

To view the Kubernetes clusters connected to your project,
group, or instance, open the cluster's page according to
your cluster's level.

**Project-level clusters:**

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.

**Group-level clusters:**

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Kubernetes**.

**Instance-level clusters:**

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Kubernetes**.

## Security implications for clusters connected with certificates

> Connecting clusters to GitLab through cluster certificates was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
The whole cluster security is based on a model where [developers](../../../permissions.md)
are trusted, so **only trusted users should be allowed to control your clusters**.

The use of cluster certificates to connect your cluster grants
access to a wide set of functionalities needed to successfully
build and deploy a containerized application. Bear in mind that
the same credentials are used for all the applications running
on the cluster.
