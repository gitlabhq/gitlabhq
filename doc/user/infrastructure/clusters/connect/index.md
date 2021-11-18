---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Connect a cluster to GitLab **(FREE)**

The [certificate-based Kubernetes integration with GitLab](../index.md)
was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)
in GitLab 14.5. To connect your clusters, use the [GitLab Kubernetes Agent](../../../clusters/agent/index.md).

<!-- TBA: (We need to resolve https://gitlab.com/gitlab-org/gitlab/-/issues/343660 before adding this line)
If you don't have a cluster yet, create one and connect it to GitLab through the Agent.
You can also create a new cluster from GitLab using [Infrastructure as Code](../../iac/index.md#create-a-new-cluster-through-iac).
-->

## Supported cluster versions

GitLab is committed to support at least two production-ready Kubernetes minor
versions at any given time. We regularly review the versions we support, and
provide a three-month deprecation period before we remove support of a specific
version. The range of supported versions is based on the evaluation of:

- The versions supported by major managed Kubernetes providers.
- The versions [supported by the Kubernetes community](https://kubernetes.io/releases/version-skew-policy/#supported-versions).

GitLab supports the following Kubernetes versions, and you can upgrade your
Kubernetes version to any supported version at any time:

- 1.20 (support ends on July 22, 2022)
- 1.19 (support ends on February 22, 2022)
- 1.18 (support ends on November 22, 2021)
- 1.17 (support ends on September 22, 2021)

[Adding support to other versions of Kubernetes is managed under this epic](https://gitlab.com/groups/gitlab-org/-/epics/4827).

Some GitLab features may support versions outside the range provided here.

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
