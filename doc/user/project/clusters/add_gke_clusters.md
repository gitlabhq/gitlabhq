---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Adding GKE clusters

GitLab supports adding new and existing GKE clusters.

## GKE requirements

Before creating your first cluster on Google GKE with GitLab's integration, make sure the following
requirements are met:

- A [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
  set up with access.
- The Kubernetes Engine API and related service are enabled. It should work immediately but may
  take up to 10 minutes after you create a project. For more information see the
  ["Before you begin" section of the Kubernetes Engine docs](https://cloud.google.com/kubernetes-engine/docs/quickstart#before-you-begin).

## New GKE cluster

Starting from [GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/25925), all the GKE clusters
provisioned by GitLab are [VPC-native](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips).

### Important notes

Note the following:

- The [Google authentication integration](../../../integration/google.md) must be enabled in GitLab
  at the instance level. If that's not the case, ask your GitLab administrator to enable it. On
  GitLab.com, this is enabled.
- Starting from [GitLab 12.1](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/55902), all GKE clusters
  created by GitLab are RBAC-enabled. Take a look at the [RBAC section](add_remove_clusters.md#rbac-cluster-resources) for
  more information.
- Starting from [GitLab 12.5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18341), the
  cluster's pod address IP range will be set to /16 instead of the regular /14. /16 is a CIDR
  notation.
- GitLab requires basic authentication enabled and a client certificate issued for the cluster to
  set up an [initial service account](add_remove_clusters.md#access-controls). Starting from [GitLab
  11.10](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/58208), the cluster creation process will
  explicitly request that basic authentication and client certificate is enabled.

### Creating the cluster on GKE

To create and add a new Kubernetes cluster to your project, group, or instance:

1. Navigate to your:
   - Project's **{cloud-gear}** **Operations > Kubernetes** page, for a project-level cluster.
   - Group's **{cloud-gear}** **Kubernetes** page, for a group-level cluster.
   - **{admin}** **Admin Area >** **{cloud-gear}** **Kubernetes** page, for an instance-level cluster.
1. Click **Add Kubernetes cluster**.
1. Under the **Create new cluster** tab, click **Google GKE**.
1. Connect your Google account if you haven't done already by clicking the
   **Sign in with Google** button.
1. Choose your cluster's settings:
   - **Kubernetes cluster name** - The name you wish to give the cluster.
   - **Environment scope** - The [associated environment](index.md#setting-the-environment-scope-premium) to this cluster.
   - **Google Cloud Platform project** - Choose the project you created in your GCP
     console that will host the Kubernetes cluster. Learn more about
     [Google Cloud Platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
   - **Zone** - Choose the [region zone](https://cloud.google.com/compute/docs/regions-zones/)
     under which the cluster will be created.
   - **Number of nodes** - Enter the number of nodes you wish the cluster to have.
   - **Machine type** - The [machine type](https://cloud.google.com/compute/docs/machine-types)
     of the Virtual Machine instance that the cluster will be based on.
   - **Enable Cloud Run for Anthos** - Check this if you want to use Cloud Run for Anthos for this cluster.
     See the [Cloud Run for Anthos section](#cloud-run-for-anthos) for more information.
   - **GitLab-managed cluster** - Leave this checked if you want GitLab to manage namespaces and service accounts for this cluster.
     See the [Managed clusters section](index.md#gitlab-managed-clusters) for more information.
1. Finally, click the **Create Kubernetes cluster** button.

After a couple of minutes, your cluster will be ready to go. You can now proceed
to install some [pre-defined applications](index.md#installing-applications).

### Cloud Run for Anthos

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16566) in GitLab 12.4.

You can choose to use Cloud Run for Anthos in place of installing Knative and Istio
separately after the cluster has been created. This means that Cloud Run
(Knative), Istio, and HTTP Load Balancing will be enabled on the cluster at
create time and cannot be [installed or uninstalled](../../clusters/applications.md) separately.

## Existing GKE cluster

For information on adding an existing GKE cluster, see
[Existing Kubernetes cluster](add_remove_clusters.md#existing-kubernetes-cluster).
