---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# New GKE cluster through IaC

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
1. [Add your GCP credentials to GitLab](#add-your-gcp-credentials-to-gitlab).
1. [Configure your project](#configure-your-project).
1. [Deploy your cluster](#deploy-your-cluster).

## Import the example project

Start by [importing the example project by URL](../../../project/import/repo_by_url.md). Use `https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-gke.git` as URL.

## Add your GCP credentials to GitLab

After importing the project, you need to set up [CI environment variables](../../../../ci/variables/index.md) to associate your cluster on GCP to your group in GitLab.

We advise that you [set environment variables through the GitLab UI](../../../../ci/variables/index.md#add-a-cicd-variable-to-a-project)
so that your credentials are not exposed through the code. To do so, follow the steps below.

### Prepare your credentials on GCP

1. Create a [GCP service account](https://cloud.google.com/docs/authentication/getting-started) to authenticate GCP with GitLab. It needs the following roles: `Computer Network Viewer`, `Kubernetes Engine Admin`, and `Service Account User`.
1. Download the JSON file with the service account key.
1. On your computer, encode the JSON file to `base64` (replace `/path/to/sa-key.json` to the path to your key):

   ```shell
   base64 /path/to/sa-key.json | tr -d \\n`
   ```

1. Use the output of this command as the `BASE64_GOOGLE_CREDENTIALS` environment variable in the next step.

### Add your credentials to GitLab as environment variables

1. On GitLab, from your project's sidebar, go to **Settings > CI/CD** and expand **Variables**.
1. Add your `GITLAB_TOKEN` ([personal access token](../../../profile/personal_access_tokens.md)).
1. Add the variable `BASE64_GOOGLE_CREDENTIALS` from the previous step.

## Configure your project

After authenticating with GCP, replace the project's defaults from the example
project with your own. To do so, edit the files as described below.

Edit `gke.tf`:

1. **(Required)** Replace the GCP `project` with a unique project name.
1. **(Optional)** Choose the `name` of your cluster.
1. **(Optional)** Choose the `region` and `zone` that you would like to deploy your cluster to.
1. Push the changes to your project's default branch.

Edit `group_cluster.tf`:

1. **(Required)**: Replace the `full_path` with the path to your group.
1. **(Optional)**: Choose your cluster base domain through `domain`.
1. **(Optional)**: Choose your environment through `environment_scope`.
1. Push the changes to your project's default branch.

Refer to the [GitLab Terraform provider](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs) and the [Google Terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference) documentation for further resource options.

## Deploy your cluster

After adjusting the files in the previous step, manually trigger the deployment of your cluster. In GitLab:

1. From your project's sidebar, go to **CI/CD > Pipelines**.
1. Select the dropdown icon (**{angle-down}**) next to the play icon (**{play}**).
1. Select **deploy** to manually trigger the deployment job.

When the pipeline finishes successfully, you can see your new cluster:

- In GCP: on your [GCP console's Kubernetes list](https://console.cloud.google.com/kubernetes/list).
- In GitLab: from your project's sidebar, select **Infrastructure > Kubernetes clusters**.
