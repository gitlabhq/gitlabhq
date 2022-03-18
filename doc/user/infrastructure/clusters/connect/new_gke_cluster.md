---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Create a Google GKE cluster

Learn how to create a new cluster on Google Kubernetes Engine (GKE) through
[Infrastructure as Code (IaC)](../../index.md). This process uses the Google
and Kubernetes Terraform providers create GKE clusters. You connect the clusters to GitLab
by using the GitLab agent for Kubernetes.

**Prerequisites:**

- A [Google Cloud Platform (GCP) service account](https://cloud.google.com/docs/authentication/getting-started).
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

1. On the top bar, select **Menu > Create new project**.
1. Select **Import project**.
1. Select **Repo by URL**.
1. For the **Git repository URL**, enter `https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke.git`.
1. Complete the fields and select **Create project**.

This project provides you with:

- A [cluster on Google Cloud Platform (GCP)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/gke.tf)
with defaults for name, location, node count, and Kubernetes version.
- The [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/agent.tf) installed in the cluster.

## Register the agent

To create a GitLab agent for Kubernetes:

1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select **Actions**.
1. From the **Select an agent** dropdown list, select `gke-agent` and select **Register an agent**.
1. GitLab generates a registration token for the agent. Securely store this secret token, as you will need it later.
1. GitLab provides an address for the agent server (KAS), which you will also need later.

## Create your GCP credentials

To set up your project to communicate to GCP and the GitLab API:

1. Create a [GitLab personal access token](../../../profile/personal_access_tokens.md) with
   `api` scope. The Terraform script uses it to connect the cluster to your GitLab group. Take note of the generated token. You will
   need it when you [configure your project](#configure-your-project).
1. To authenticate GCP with GitLab, create a [GCP service account](https://cloud.google.com/docs/authentication/getting-started)
with following roles: `Compute Network Viewer`, `Kubernetes Engine Admin`, `Service Account User`, and `Service Account Admin`. Both User and Admin
service accounts are necessary. The User role impersonates the [default service account](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account)
when [creating the node pool](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#node-pool-management).
The Admin role creates a service account in the `kube-system` namespace.
1. Download the JSON file with the service account key you created in the previous step.
1. On your computer, encode the JSON file to `base64` (replace `/path/to/sa-key.json` to the path to your key):

   ```shell
   base64 /path/to/sa-key.json | tr -d \\n
   ```

1. Use the output of this command as the `BASE64_GOOGLE_CREDENTIALS` environment variable in the next step.

## Configure your project

Use CI/CD environment variables to configure your project.

**Required configuration:**

1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Set the variable `BASE64_GOOGLE_CREDENTIALS` to the `base64` encoded JSON file you just created.
1. Set the variable `TF_VAR_gcp_project` to your GCP's `project` name.

**Optional configuration:**

The file [`variables.tf`](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/variables.tf)
contains other variables that you can override according to your needs:

- `TF_VAR_gcp_region`: Set your cluster's region.
- `TF_VAR_cluster_name`: Set your cluster's name.
- `TF_VAR_cluster_description`: Set a description for the cluster. We recommend setting this to `$CI_PROJECT_URL` to create a reference to your GitLab project on your GCP cluster detail page. This way you know which project was responsible for provisioning the cluster you see on the GCP dashboard.
- `TF_VAR_machine_type`: Set the machine type for the Kubernetes nodes.
- `TF_VAR_node_count`: Set the number of Kubernetes nodes.
- `TF_VAR_agent_version`: Set the version of the GitLab agent.
- `TF_VAR_agent_namespace`: Set the Kubernetes namespace for the GitLab agent.

Refer to the [Google Terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference) and the [Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) documentation for further resource options.

## Provision your cluster

After configuring your project, manually trigger the provisioning of your cluster. In GitLab:

1. On the left sidebar, go to **CI/CD > Pipelines**.
1. Next to **Play** (**{play}**), select the dropdown icon (**{angle-down}**).
1. Select **Deploy** to manually trigger the deployment job.

When the pipeline finishes successfully, you can see your new cluster:

- In GCP: on your [GCP console's Kubernetes list](https://console.cloud.google.com/kubernetes/list).
- In GitLab: from your project's sidebar, select **Infrastructure > Kubernetes clusters**.

## Use your cluster

After you provision the cluster, it is connected to GitLab and is ready for deployments. To check the connection:

1. On the left sidebar, select **Infrastructure > Kubernetes clusters**.
1. In the list, view the **Connection status** column.

For more information about the capabilities of the connection, see [the GitLab agent for Kubernetes documentation](../index.md).

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
      - deploy
      - cleanup

    destroy:
      extends: .destroy
      needs: []
    ```

1. On the left sidebar, select **CI/CD > Pipelines** and select the most recent pipeline.
1. For the `destroy` job, select **Play** (**{play}**).
