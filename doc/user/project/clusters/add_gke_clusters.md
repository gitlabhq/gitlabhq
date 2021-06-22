---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GKE clusters (DEPRECATED) **(FREE)**

> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/6049) in GitLab 14.0.

WARNING:
Use [Infrastrucure as Code](../../infrastructure/index.md) to create new clusters. The method described in this document is deprecated as of GitLab 14.0.

Through GitLab, you can create new clusters and add existing clusters hosted on Amazon Elastic
Kubernetes Service (EKS).

GitLab supports adding new and existing GKE clusters.

## GKE requirements

Before creating your first cluster on Google GKE with GitLab integration, make sure the following
requirements are met:

- A [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
  set up with access.
- The Kubernetes Engine API and related service are enabled. It should work immediately but may
  take up to 10 minutes after you create a project. For more information see the
  ["Before you begin" section of the Kubernetes Engine docs](https://cloud.google.com/kubernetes-engine/docs/quickstart#before-you-begin).

## Add an existing GKE cluster

If you already have a GKE cluster and want to integrate it with GitLab,
see how to [add an existing cluster](add_existing_cluster.md).

## Create new GKE cluster

Starting from [GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/25925), all the GKE clusters
provisioned by GitLab are [VPC-native](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips).

Note the following:

- The [Google authentication integration](../../../integration/google.md) must be enabled in GitLab
  at the instance level. If that's not the case, ask your GitLab administrator to enable it. On
  GitLab.com, this is enabled.
- Starting from [GitLab 12.1](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/55902), all GKE clusters
  created by GitLab are RBAC-enabled. Take a look at the [RBAC section](cluster_access.md#rbac-cluster-resources) for
  more information.
- Starting from [GitLab 12.5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18341), the
  cluster's pod address IP range is set to `/16` instead of the regular `/14`. `/16` is a CIDR
  notation.
- GitLab requires basic authentication enabled and a client certificate issued for the cluster to
  set up an [initial service account](cluster_access.md). In [GitLab versions
  11.10 and later](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/58208), the cluster creation process
  explicitly requests GKE to create clusters with basic authentication enabled and a client
  certificate.

### Creating the cluster on GKE

To create and add a new Kubernetes cluster to your project, group, or instance:

1. Navigate to your:
   - Project's **{cloud-gear}** **Infrastructure > Kubernetes clusters** page, for a project-level
     cluster.
   - Group's **{cloud-gear}** **Kubernetes** page, for a group-level cluster.
   - **Menu >** **{admin}** **Admin >** **{cloud-gear}** **Kubernetes** page, for an instance-level cluster.
1. Click **Integrate with a cluster certificate**.
1. Under the **Create new cluster** tab, click **Google GKE**.
1. Connect your Google account if you haven't done already by clicking the
   **Sign in with Google** button.
1. Choose your cluster's settings:
   - **Kubernetes cluster name** - The name you wish to give the cluster.
   - **Environment scope** - The [associated environment](multiple_kubernetes_clusters.md#setting-the-environment-scope) to this cluster.
   - **Google Cloud Platform project** - Choose the project you created in your GCP
     console to host the Kubernetes cluster. Learn more about
     [Google Cloud Platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
   - **Zone** - Choose the [region zone](https://cloud.google.com/compute/docs/regions-zones/)
     under which to create the cluster.
   - **Number of nodes** - Enter the number of nodes you wish the cluster to have.
   - **Machine type** - The [machine type](https://cloud.google.com/compute/docs/machine-types)
     of the Virtual Machine instance to base the cluster on.
   - **Enable Cloud Run for Anthos** - Check this if you want to use Cloud Run for Anthos for this cluster.
     See the [Cloud Run for Anthos section](#cloud-run-for-anthos) for more information.
   - **GitLab-managed cluster** - Leave this checked if you want GitLab to manage namespaces and service accounts for this cluster.
     See the [Managed clusters section](gitlab_managed_clusters.md) for more information.
1. Finally, click the **Create Kubernetes cluster** button.

After a couple of minutes, your cluster is ready.

### Cloud Run for Anthos

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16566) in GitLab 12.4.

You can choose to use Cloud Run for Anthos in place of installing Knative and Istio
separately after the cluster has been created. This means that Cloud Run
(Knative), Istio, and HTTP Load Balancing are enabled on the cluster
from the start, and cannot be installed or uninstalled.
