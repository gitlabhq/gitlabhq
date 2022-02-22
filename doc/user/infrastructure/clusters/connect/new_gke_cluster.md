---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# New GKE cluster through IaC (DEPRECATED)

> [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

WARNING:
The process described on this page uses cluster certificates to connect the
new cluster to GitLab, [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
You can still create a cluster and then connect it to GitLab through the [agent](../index.md).
[An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/343660)
to migrate this functionality to the [agent](../index.md).

Learn how to create a new cluster on Google Kubernetes Engine (GKE) through
[Infrastructure as Code (IaC)](../../index.md).

This process combines the GitLab Terraform and Google Terraform providers
with Kubernetes to help you create GKE clusters and deploy them through
GitLab.

This document describes how to set up a [group-level cluster](../../../group/clusters/index.md) on GKE by importing an example project to get you started.
You can then modify the project files according to your needs.

**Prerequisites:**

- A GitLab group.
- A GitLab user with the Maintainer role in the group.
- A [GitLab personal access token](../../../profile/personal_access_tokens.md) with `api` access, created by a user with at least the Maintainer role in the group.
- A [Google Cloud Platform (GCP) service account](https://cloud.google.com/docs/authentication/getting-started).

**Steps:**

1. [Import the example project](#import-the-example-project).
1. [Create your GCP and GitLab credentials](#create-your-gcp-and-gitlab-credentials).
1. [Configure your project](#configure-your-project).
1. [Deploy your cluster](#deploy-your-cluster).

## Import the example project

To create a new group-level cluster from GitLab using Infrastructure as Code, it is necessary
to create a project to manage the cluster from. In this tutorial, we import a pre-configured
sample project to help you get started.

Start by [importing the example project by URL](../../../project/import/repo_by_url.md). Use `https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke.git` as URL.

This project provides you with the following resources:

- A [cluster on Google Cloud Platform (GCP)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/gke.tf)
with defaults for name, location, node count, and Kubernetes version.
- A [`gitlab-admin` K8s service account](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/gitlab-admin.tf) with `cluster-admin` privileges.
- The new group-level cluster connected to GitLab.
- Pre-configures Terraform files:

   ```plaintext
   ├── backend.tf         # State file Location Configuration
   ├── gke.tf             # Google GKE Configuration
   ├── gitlab-admin.tf    # Adding kubernetes service account
   └── group_cluster.tf   # Registering kubernetes cluster to GitLab `apps` Group
   ```

## Create your GCP and GitLab credentials

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

**Required configuration:**

Use CI/CD environment variables to configure your project as detailed below.

**Required configuration:**

1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Set the variable `TF_VAR_gitlab_token` to the GitLab personal access token you just created.
1. Set the variable `BASE64_GOOGLE_CREDENTIALS` to the `base64` encoded JSON file you just created.
1. Set the variable `TF_VAR_gcp_project` to your GCP's `project` name.
1. Set the variable `TF_VAR_gitlab_group` to the name of the group you want to connect your cluster to. If your group's URL is `https://gitlab.example.com/my-example-group`, `my-example-group` is your group's name.

**Optional configuration:**

The file [`variables.tf`](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke/-/blob/master/variables.tf)
contains other variables that you can override according to your needs:

- `TF_VAR_gcp_region`: Set your cluster's region.
- `TF_VAR_cluster_name`: Set your cluster's name.
- `TF_VAR_machine_type`: Set the machine type for the Kubernetes nodes.
- `TF_VAR_cluster_description`: Set a description for the cluster. We recommend setting this to `$CI_PROJECT_URL` to create a reference to your GitLab project on your GCP cluster detail page. This way you know which project was responsible for provisioning the cluster you see on the GCP dashboard.
- `TF_VAR_base_domain`: Set to the base domain to provision resources under.
- `TF_VAR_environment_scope`: Set to the environment scope for your cluster.

Refer to the [GitLab Terraform provider](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs) and the [Google Terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference) documentation for further resource options.

## Deploy your cluster

After configuring your project, manually trigger the deployment of your cluster. In GitLab:

1. From your project's sidebar, go to **CI/CD > Pipelines**.
1. Select the dropdown icon (**{angle-down}**) next to the play icon (**{play}**).
1. Select **deploy** to manually trigger the deployment job.

When the pipeline finishes successfully, you can see your new cluster:

- In GCP: on your [GCP console's Kubernetes list](https://console.cloud.google.com/kubernetes/list).
- In GitLab: from your project's sidebar, select **Infrastructure > Kubernetes clusters**.
