---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create a Google GKE cluster
---

Learn how to create a new cluster on Google Kubernetes Engine (GKE) through
[Infrastructure as Code (IaC)](../../_index.md). This process uses the Google
and Kubernetes Terraform providers create GKE clusters. You connect the clusters to GitLab
by using the GitLab agent for Kubernetes.

NOTE:
Every new Google Cloud Platform (GCP) account receives [$300 in credit](https://console.cloud.google.com/freetrial),
and in partnership with Google, GitLab is able to offer an additional $200 for new
GCP accounts to get started with the GitLab integration with Google Kubernetes Engine.
[Follow this link](https://cloud.google.com/partners?pcn_code=0014M00001h35gDQAQ&hl=en#contact-form)
and apply for credit.

**Before you begin:**

- A [Google Cloud Platform (GCP) service account](https://cloud.google.com/docs/authentication#service-accounts).
- [A runner](https://docs.gitlab.com/runner/install/) you can use to run the GitLab CI/CD pipeline.

**Steps:**

1. [Import the example project](#import-the-example-project).
1. [Register the agent for Kubernetes](#register-the-agent).
1. [Create your GCP credentials](#create-your-gcp-credentials).
1. [Configure your project](#configure-your-project).
1. [Provision your cluster](#provision-your-cluster).

## Import the example project

To create a cluster from GitLab using Infrastructure as Code, you must
create a project to manage the cluster from. In this tutorial, you start with
a sample project and modify it according to your needs.

Start by [importing the example project by URL](../../../project/import/repo_by_url.md).

To import the project:

1. In GitLab, on the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. On the right of the page, select **New project**.
1. Select **Import project**.
1. Select **Repository by URL**.
1. For the **Git repository URL**, enter `https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke.git`.
1. Complete the fields and select **Create project**.

This project provides you with:

- A [cluster on Google Cloud Platform (GCP)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/gke.tf)
  with defaults for name, location, node count, and Kubernetes version.
- The [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/agent.tf) installed in the cluster.

## Register the agent

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81054) in GitLab 14.9: A [flag](../../../../administration/feature_flags.md) named `certificate_based_clusters` changed the **Actions** menu to focus on the agent rather than certificates. Disabled by default.

To create a GitLab agent for Kubernetes:

1. On the left sidebar, select **Operate > Kubernetes clusters**.
1. Select **Connect a cluster (agent)**.
1. From the **Select an agent or enter a name to create new** dropdown list, choose your agent's name and select **Register**.
1. GitLab generates a registration token for the agent. Securely store this secret token, as you will need it later.
1. Optional. If you use Helm, GitLab provides an address for the agent server (KAS) in the Helm command example. You need this for later.

## Create your GCP credentials

To set up your project to communicate to GCP and the GitLab API:

1. To authenticate GCP with GitLab, create a [GCP service account](https://cloud.google.com/docs/authentication#service-accounts)
   with following roles: `Compute Network Viewer`, `Kubernetes Engine Admin`, `Service Account User`, and `Service Account Admin`. Both User and Admin
   service accounts are necessary. The User role impersonates the [default service account](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account)
   when [creating the node pool](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#node-pool-management).
   The Admin role creates a service account in the `kube-system` namespace.
1. Download the JSON file with the service account key you created in the previous step.
1. On your computer, encode the JSON file to `base64` (replace `/path/to/sa-key.json` to the path to your key):

   ::Tabs

   :::TabTitle MacOS

   ```shell
   base64 -i /path/to/sa-key.json | tr -d \\n
   ```

   :::TabTitle Linux

   ```shell
   base64 /path/to/sa-key.json | tr -d \\n
   ```

   ::EndTabs

1. Use the output of this command as the `BASE64_GOOGLE_CREDENTIALS` environment variable in the next step.

## Configure your project

Use CI/CD environment variables to configure your project.

**Required configuration:**

1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Set the variable `BASE64_GOOGLE_CREDENTIALS` to the `base64` encoded JSON file you just created.
1. Set the variable `TF_VAR_gcp_project` to your GCP `project` ID.
1. Set the variable `TF_VAR_agent_token` to the agent token displayed in the previous task.
1. Set the variable `TF_VAR_kas_address` to the agent server address displayed in the previous task.

**Optional configuration:**

The file [`variables.tf`](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/variables.tf)
contains other variables that you can override according to your needs:

- `TF_VAR_gcp_region`: Set your cluster's region.
- `TF_VAR_cluster_name`: Set your cluster's name.
- `TF_VAR_cluster_description`: Set a description for the cluster. We recommend setting this to `$CI_PROJECT_URL` to create a reference to your GitLab project on your GCP cluster detail page. This way you know which project was responsible for provisioning the cluster you see on the GCP dashboard.
- `TF_VAR_machine_type`: Set the machine type for the Kubernetes nodes.
- `TF_VAR_node_count`: Set the number of Kubernetes nodes.
- `TF_VAR_agent_namespace`: Set the Kubernetes namespace for the GitLab agent.

Refer to the [Google Terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference) and the [Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) documentation for further resource options.

## Enable Kubernetes Engine API

From the Google Cloud console, enable the [Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com).

## Provision your cluster

After configuring your project, manually trigger the provisioning of your cluster. In GitLab:

1. On the left sidebar, select **Build > Pipelines**.
1. Select **New pipeline**.
1. Next to **Play** (**{play}**), select the dropdown list icon (**{chevron-lg-down}**).
1. Select **Deploy** to manually trigger the deployment job.

When the pipeline finishes successfully, you can see your new cluster:

- In GCP: on your [GCP console's Kubernetes list](https://console.cloud.google.com/kubernetes/list).
- In GitLab: from your project's sidebar, select **Operate > Kubernetes clusters**.

## Use your cluster

After you provision the cluster, it is connected to GitLab and is ready for deployments. To check the connection:

1. On the left sidebar, select **Operate > Kubernetes clusters**.
1. In the list, view the **Connection status** column.

For more information about the capabilities of the connection, see [the GitLab agent for Kubernetes documentation](../_index.md).

## Remove the cluster

A cleanup job is not included in your pipeline by default. To remove all created resources, you
must modify your GitLab CI/CD template before running the cleanup job.

To remove all resources:

1. Add the following to your `.gitlab-ci.yml` file:

   ```yaml
   stages:
     - init
     - validate
     - build
     - test
     - deploy
     - cleanup

   destroy:
     extends: .terraform:destroy
     needs: []
   ```

1. On the left sidebar, select **Build > Pipelines** and select the most recent pipeline.
1. For the `destroy` job, select **Play** (**{play}**).
