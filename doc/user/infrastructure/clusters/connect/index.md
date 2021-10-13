---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Connect a cluster to GitLab **(FREE)**

You can create new or connect existing clusters to GitLab through different [levels](#cluster-levels),
using different [methods](#methods-to-connect-a-cluster-to-gitlab).

Before getting started:

1. Check the [supported Kubernetes cluster versions](#supported-cluster-versions).
1. Define the [cluster level](#cluster-levels) according to your case.

After that:

1. Choose the [method](#methods-to-connect-a-cluster-to-gitlab)
to connect your cluster according to your case.
1. [View your clusters](#view-your-clusters) connected to GitLab.

## Methods to connect a cluster to GitLab

GitLab offers three methods to connect existing and create new clusters:

- **GitLab Kubernetes Agent**: the best solution to
[connect existing clusters](#connect-existing-clusters-to-gitlab).
- **Infrastructure as Code**: it's a broader infrastructure management
toolset that includes managing your cluster. It's the recommended
solution to [create a new cluster](#create-new-clusters-from-gitlab)
from GitLab.
- **Certificate-based method**: our first and legacy solution uses
cluster certificates to connect your cluster to GitLab. It is no longer
recommended for [security implications](#security-implications-for-clusters-connected-with-certificates).

### Connect existing clusters to GitLab

To safely connect and configure an existing cluster on the **project level**,
we **recommend** using the [GitLab Kubernetes Agent](../../../clusters/agent/index.md).
We are working to support [the Agent for connecting a cluster at the group level](https://gitlab.com/groups/gitlab-org/-/epics/5784).

Alternatively, you can use [cluster certificates](../../../project/clusters/add_existing_cluster.md)
to connect clusters in all levels (projects, group, instance). However,
for [security implications](#security-implications-for-clusters-connected-with-certificates),
we don't recommend using this method.

### Create new clusters from GitLab

To safely create new clusters from GitLab, use
[Infrastructure as Code](../../iac/index.md#create-a-new-cluster-through-iac).

The [certificate-based method to create a new cluster](../../../project/clusters/add_remove_clusters.md)
is still available through the GitLab UI but was **deprecated** in GitLab 14.0.
If possible, we don't recommend using this method.

### Connect multiple clusters to a single project

To connect multiple clusters to a single project in GitLab,
we **recommend** using the [GitLab Kubernetes Agent](../../../clusters/agent/index.md).

You can also use the [certificate-based method](../../../project/clusters/multiple_kubernetes_clusters.md),
but, for [security implications](#security-implications-for-clusters-connected-with-certificates),
we don't recommend using this method.

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

## Cluster levels

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

WARNING:
The whole cluster security is based on a model where [developers](../../../permissions.md)
are trusted, so **only trusted users should be allowed to control your clusters**.

The use of cluster certificates to connect your cluster grants
access to a wide set of functionalities needed to successfully
build and deploy a containerized application. Bear in mind that
the same credentials are used for all the applications running
on the cluster.
