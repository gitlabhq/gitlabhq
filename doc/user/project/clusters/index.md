# Connecting GitLab with GKE

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/35954) in 10.1.

CAUTION: **Warning:**
The Cluster integration is currently in **Beta**.

Connect your project to Google Container Engine (GKE) in a few steps.

With a cluster associated to your project, you can use Review Apps, deploy your
applications, run your pipelines, and much more in an easy way.

NOTE: **Note:**
The Cluster integration will eventually supersede the
[Kubernetes integration](../integrations/kubernetes.md). For the moment,
you can create only one cluster.

## Prerequisites

In order to be able to manage your GKE cluster through GitLab, the following
prerequisites must be met:

- The [Google authentication integration](../../../integration/google.md) must
  be enabled in GitLab at the instance level. If that's not the case, ask your
  administrator to enable it.
- Your associated Google account must have the right privileges to manage
  clusters on GKE. That would mean that a
  [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
  must be set up.
- You must have Master [permissions] in order to be able to access the **Cluster**
  page.

If all of the above requirements are met, you can proceed to add a new cluster.

## Adding a cluster

NOTE: **Note:**
You need Master [permissions] and above to add a cluster.

To add a new cluster:

1. Navigate to your project's **CI/CD > Cluster** page.
1. Connect your Google account if you haven't done already by clicking the
   "Sign-in with Google" button.
1. Fill in the requested values:
  - **Cluster name** (required) - The name you wish to give the cluster.
  - **GCP project ID** (required) - The ID of the project you created in your GCP
    console that will host the Kubernetes cluster. This must **not** be confused
    with the project name. Learn more about [Google Cloud Platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
  - **Zone** - The zone under which the cluster will be created. Read more about
    [the available zones](https://cloud.google.com/compute/docs/regions-zones/).
  - **Number of nodes** - The number of nodes you wish the cluster to have.
  - **Machine type** - The machine type of the Virtual Machine instance that
    the cluster will be based on. Read more about [the available machine types](https://cloud.google.com/compute/docs/machine-types).
  - **Project namespace** - The unique namespace for this project. By default you
    don't have to fill it in; by leaving it blank, GitLab will create one for you.
1. Click the **Create cluster** button.

After a few moments your cluster should be created. If something goes wrong,
you will be notified.

Now, you can proceed to [enable the Cluster integration](#enabling-or-disabling-the-cluster-integration).

## Enabling or disabling the Cluster integration

After you have successfully added your cluster information, you can enable the
Cluster integration:

1. Click the "Enabled/Disabled" switch
1. Hit **Save** for the changes to take effect

You can now start using your Kubernetes cluster for your deployments.

To disable the Cluster integration, follow the same procedure.

## Removing the Cluster integration

NOTE: **Note:**
You need Master [permissions] and above to remove a cluster integration.

NOTE: **Note:**
When you remove a cluster, you only remove its relation to GitLab, not the
cluster itself. To remove the cluster, you can do so by visiting the GKE
dashboard or using `kubectl`.

To remove the Cluster integration from your project, simply click on the
**Remove integration** button. You will then be able to follow the procedure
and [add a cluster](#adding-a-cluster) again.

[permissions]: ../../permissions.md
