---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create an Azure AKS cluster
---

You can create a cluster on Azure Kubernetes Service (AKS) through
[Infrastructure as Code (IaC)](../../_index.md). This process uses the Azure and
Kubernetes Terraform providers to create AKS clusters. You connect the clusters to GitLab
by using the GitLab agent for Kubernetes.

**Before you begin:**

- A Microsoft Azure account, with a set of configured
  [security credentials](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli).
- [A runner](https://docs.gitlab.com/runner/install/) you can use to run the GitLab CI/CD pipeline.

**Steps:**

1. [Import the example project](#import-the-example-project).
1. [Register the agent for Kubernetes](#register-the-agent).
1. [Configure your project](#configure-your-project).
1. [Provision your cluster](#provision-your-cluster).

## Import the example project

To create a cluster from GitLab using Infrastructure as Code, you must
create a project to manage the cluster from. In this tutorial, you start with
a sample project and modify it according to your needs.

Start by [importing the example project by URL](../../../project/import/repo_by_url.md).

To import the project:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Import project**.
1. Select **Repository by URL**.
1. For the **Git repository URL**, enter `https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks.git`.
1. Complete the fields and select **Create project**.

This project provides you with:

- An [Azure Kubernetes Service (AKS)](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks/-/blob/main/aks.tf) cluster.
- The [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks/-/blob/main/agent.tf) installed in the cluster.

## Register the agent

To create a GitLab agent for Kubernetes:

1. On the left sidebar, select **Operate > Kubernetes clusters**.
1. Select **Connect a cluster (agent)**.
1. From the **Select an agent** dropdown list, select `aks-agent` and select **Register an agent**.
1. GitLab generates a registration token for the agent. Securely store this secret token, as you will need it later.
1. GitLab provides an address for the agent server (KAS), which you will also need later.

## Configure your project

Use CI/CD environment variables to configure your project.

**Required configuration:**

1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Set the variable `ARM_CLIENT_ID` to your Azure client ID.
1. Set the variable `ARM_CLIENT_SECRET` to your Azure client secret.
1. Set the variable `ARM_TENANT_ID` to your service principal.
1. Set the variable `TF_VAR_agent_token` to the agent token displayed in the previous task.
1. Set the variable `TF_VAR_kas_address` to the agent server address displayed in the previous task.

**Optional configuration:**

The file [`variables.tf`](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/examples/gitlab-terraform-aks/-/blob/main/variables.tf)
contains other variables that you can override according to your needs:

- `TF_VAR_location`: Set your cluster's region.
- `TF_VAR_cluster_name`: Set your cluster's name.
- `TF_VAR_kubernetes_version`: Set the version of Kubernetes.
- `TF_VAR_create_resource_group`: Allow to enable or disable the creation of a new resource group. (Default set to true).
- `TF_VAR_resource_group_name`: Set the name of resource group.
- `TF_VAR_agent_namespace`: Set the Kubernetes namespace for the GitLab agent.

See the [Azure Terraform provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) and the [Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) documentation for further resource options.

## Provision your cluster

After configuring your project, manually trigger the provisioning of your cluster. In GitLab:

1. On the left sidebar, select **Build > Pipelines**.
1. Next to **Play** (**{play}**), select the dropdown list icon (**{chevron-lg-down}**).
1. Select **Deploy** to manually trigger the deployment job.

When the pipeline finishes successfully, you can view the new cluster:

- In Azure: From the [Azure portal](https://portal.azure.com/#home), select **Kubernetes services > View**.
- In GitLab: On the left sidebar, select **Operate > Kubernetes clusters**.

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
     - test
     - build
     - deploy
     - cleanup

   destroy:
     extends: .terraform:destroy
     needs: []
   ```

1. On the left sidebar, select **Build > Pipelines** and select the most recent pipeline.
1. For the `destroy` job, select **Play** (**{play}**).
