---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Connect GKE clusters through cluster certificates (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
Use [Infrastructure as Code](../../infrastructure/clusters/connect/new_gke_cluster.md)
to create a cluster hosted on Google Kubernetes Engine (GKE).

Through GitLab, you can create new and connect existing clusters
hosted on Google Kubernetes Engine (GKE).

## Connect an existing GKE cluster

If you already have a GKE cluster and want to connect it to GitLab,
use the [GitLab agent](../../clusters/agent/_index.md).

## Create a new GKE cluster from GitLab

All GKE clusters provisioned by GitLab are [VPC-native](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips).

To create a new GKE cluster from GitLab, use [Infrastructure as Code](../../infrastructure/clusters/connect/new_gke_cluster.md).

## Create a new cluster on GKE through cluster certificates

> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/6049) in GitLab 14.0.

Prerequisites:

- A [Google Cloud billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
  set up with access.
- Kubernetes Engine API and related services enabled. It should work immediately but may
  take up to 10 minutes after you create a project. For more information see the
  ["Before you begin" section of the Kubernetes Engine docs](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster#before-you-begin).

Note the following:

- The [Google authentication integration](../../../integration/google.md) must be enabled in GitLab
  at the instance level. If that's not the case, ask your GitLab administrator to enable it. On
  GitLab.com, this is enabled.
- All GKE clusters created by GitLab are RBAC-enabled. Take a look at the [RBAC section](cluster_access.md#rbac-cluster-resources) for
  more information.
- The cluster's pod address IP range is set to `/16` instead of the regular `/14`. `/16` is a CIDR
  notation.
- GitLab requires basic authentication enabled and a client certificate issued for the cluster to
  set up an [initial service account](cluster_access.md). In
  [GitLab versions 11.10 and later](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/58208), the cluster creation process
  explicitly requests GKE to create clusters with basic authentication enabled and a client
  certificate.

To create new Kubernetes clusters to your project, group, or instance, through
cluster certificates:

1. Go to your:
   - Project's **{cloud-gear}** **Operate > Kubernetes clusters** page, for a project-level
     cluster.
   - Group's **{cloud-gear}** **Kubernetes** page, for a group-level cluster.
   - The **Admin** area's **Kubernetes** page, for an instance-level cluster.
1. Select **Integrate with a cluster certificate**.
1. Under the **Create new cluster** tab, select **Google GKE**.
1. Connect your Google account if you haven't done already by selecting the
   **Sign in with Google** button.
1. Choose your cluster's settings:
   - **Kubernetes cluster name** - The name you wish to give the cluster.
   - **Environment scope** - The [associated environment](multiple_kubernetes_clusters.md#setting-the-environment-scope) to this cluster.
   - **Google Cloud Platform project** - Choose the project you created in your GCP
     console to host the Kubernetes cluster. For more information, see
     [Creating and managing projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
   - **Zone** - Choose the [region zone](https://cloud.google.com/compute/docs/regions-zones/)
     under which to create the cluster.
   - **Number of nodes** - Enter the number of nodes you wish the cluster to have.
   - **Machine type** - The [machine type](https://cloud.google.com/compute/docs/machine-resource)
     of the Virtual Machine instance to base the cluster on.
   - **Enable Cloud Run for Anthos** - Check this if you want to use Cloud Run for Anthos for this cluster.
     See the [Cloud Run for Anthos section](#cloud-run-for-anthos) for more information.
   - **GitLab-managed cluster** - Leave this checked if you want GitLab to manage namespaces and service accounts for this cluster.
     See the [Managed clusters section](gitlab_managed_clusters.md) for more information.
1. Finally, select the **Create Kubernetes cluster** button.

After a couple of minutes, your cluster is ready.

### Cloud Run for Anthos

You can choose to use Cloud Run for Anthos in place of installing Knative and Istio
separately after the cluster has been created. This means that Cloud Run
(Knative), Istio, and HTTP Load Balancing are enabled on the cluster
from the start, and cannot be installed or uninstalled.
