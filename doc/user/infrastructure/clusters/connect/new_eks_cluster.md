---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Create a new EKS cluster through IaC

Learn how to create a new cluster on Amazon Elastic Kubernetes Service (EKS) through
[Infrastructure as Code (IaC)](../../index.md).

This process combines the AWS and Kubernetes Terraform providers to help you create EKS clusters
and connect them to GitLab using the [GitLab agent for Kubernetes](../../../clusters/agent/index.md).

This document describes how to set up a Kubernetes cluster on EKS by importing an example project to get you started.
You can then modify the project files according to your needs.

**Prerequisites:**

- An Amazon Web Services (AWS) account, with a set of configured
  [security credentials](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-prereqs.html).
- [Configured GitLab Runners](https://docs.gitlab.com/runner/install/) to run the infrastructure pipeline from GitLab CI/CD.

**Steps:**

1. [Import the example project](#import-the-example-project).
1. [Register the Agent](#register-the-agent).
1. [Configure your project](#configure-your-project).
1. [Provision your cluster](#provision-your-cluster).

## Import the example project

To create a new cluster from GitLab using Infrastructure as Code, it is necessary
to create a project to manage the cluster from. In this tutorial, we import a pre-configured
sample project to help you get started.

Start by [importing the example project by URL](../../../project/import/repo_by_url.md). Use `https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks.git` as the URL.

This project provides you with the following resources:

- An Amazon [Virtual Private Cloud (VPC)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/vpc.tf).
- An Amazon [Elastic Kubernetes Service (EKS)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/eks.tf) cluster.
- The [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/agent.tf) installed into the cluster.

## Register the Agent

To create an Agent in GitLab:

1. From your project's sidebar, select **Infrastructure > Kubernetes clusters**.
1. Select **Actions**.
1. From the **Select an Agent** dropdown list, select `eks-agent` and select **Register an Agent**.
1. GitLab generates a registration token for this Agent. Securely store this secret token, as you will need it to [configure your project](#configure-your-project) below.
1. GitLab provides you with a KAS address, which will also be needed when configuring your project below.

## Configure your project

Use CI/CD environment variables to configure your project as detailed below.

**Required configuration:**

1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Set the variable `AWS_ACCESS_KEY_ID` to your AWS access key ID.
1. Set the variable `AWS_SECRET_ACCESS_KEY` to your AWS secret access key.
1. Set the variable `TF_VAR_agent_token` to the Agent token displayed in the previous step.
1. Set the variable `TF_VAR_kas_address` to the KAS address displayed in the previous step.

**Optional configuration:**

The file [`variables.tf`](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/variables.tf)
contains other variables that you can override according to your needs:

- `TF_VAR_region`: Set your cluster's region.
- `TF_VAR_cluster_name`: Set your cluster's name.
- `TF_VAR_cluster_version`: Set the version of Kubernetes.
- `TF_VAR_instance_type`: Set the instance type for the Kubernetes nodes.
- `TF_VAR_instance_count`: Set the number of Kubernetes nodes.
- `TF_VAR_agent_version`: Set the version of the GitLab Agent.
- `TF_VAR_agent_namespace`: Set the Kubernetes namespace for the GitLab Agent.

Refer to the [AWS Terraform provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) and the [Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) documentation for further resource options.

## Provision your cluster

After configuring your project, manually trigger the provisioning of your cluster. In GitLab:

1. From your project's sidebar, go to **CI/CD > Pipelines**.
1. Select the dropdown icon (**{angle-down}**) next to the play icon (**{play}**).
1. Select **deploy** to manually trigger the deployment job.

When the pipeline finishes successfully, you can see your new cluster:

- In AWS: from the [EKS console](https://console.aws.amazon.com/eks/home) select **Amazon EKS > Clusters**.
- In GitLab: from your project's sidebar, select **Infrastructure > Kubernetes clusters**.

## Removing the cluster

A cleanup job is not included in your pipeline by default. To remove all created resources, you
need to modify your GitLab CI/CD template before running the cleanup job.

To remove all resources:

1. Add the following to your `.gitlab-ci.yml`:

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

1. From your project's sidebar, go to **CI/CD > Pipelines** and select the most recent pipeline.
1. Click the play icon (**{play}**) for the `destroy` job.
