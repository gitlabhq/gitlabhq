---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create an Amazon EKS cluster
---

You can create a cluster on Amazon Elastic Kubernetes Service (EKS) through
[Infrastructure as Code (IaC)](../../_index.md). This process uses the AWS and
Kubernetes Terraform providers to create EKS clusters. You connect the clusters to GitLab
by using the GitLab agent for Kubernetes.

**Before you begin:**

- An Amazon Web Services (AWS) account, with a set of configured
  [security credentials](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-prereqs.html).
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

1. In GitLab, on the left sidebar, select **Search or go to**.
1. Select **View all my projects**.
1. On the right of the page, select **New project**.
1. Select **Import project**.
1. Select **Repository by URL**.
1. For the **Git repository URL**, enter `https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks.git`.
1. Complete the fields and select **Create project**.

This project provides you with:

- An Amazon [Virtual Private Cloud (VPC)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/vpc.tf).
- An Amazon [Elastic Kubernetes Service (EKS)](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/eks.tf) cluster.
- The [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/agent.tf) installed in the cluster.

## Register the agent

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/81054) in GitLab 14.9: A [flag](../../../../administration/feature_flags.md) named `certificate_based_clusters` changed the **Actions** menu to focus on the agent rather than certificates. Disabled by default.

To create a GitLab agent for Kubernetes:

1. On the left sidebar, select **Operate > Kubernetes clusters**.
1. Select **Connect a cluster (agent)**.
1. From the **Select an agent** dropdown list, select `eks-agent` and select **Register an agent**.
1. GitLab generates a registration token for the agent. Securely store this secret token, as you will need it later.
1. GitLab provides an address for the agent server (KAS), which you will also need later.

## Set up AWS credentials

Set up your AWS credentials when you want to authenticate AWS with GitLab.

1. Create an [IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html) or [IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html).
1. Make sure that your IAM user or role has the appropriate permissions for your project. For this example project, you must have the permissions shown below. You can expand this when you set up your own project.

   ```json
   // IAM custom Policy definition
   {
     "Version": "2012-10-17",
     "Statement": [
         {
             "Sid": "VisualEditor0",
             "Effect": "Allow",
             "Action": [
                 "ec2:*",
                 "eks:*",
                 "elasticloadbalancing:*",
                 "autoscaling:*",
                 "cloudwatch:*",
                 "logs:*",
                 "kms:DescribeKey",
                 "iam:AddRoleToInstanceProfile",
                 "iam:AttachRolePolicy",
                 "iam:CreateInstanceProfile",
                 "iam:CreateRole",
                 "iam:CreateServiceLinkedRole",
                 "iam:GetRole",
                 "iam:ListAttachedRolePolicies",
                 "iam:ListRolePolicies",
                 "iam:ListRoles",
                 "iam:PassRole",
                 // required for destroy step
                 "iam:DetachRolePolicy",
                 "iam:ListInstanceProfilesForRole",
                 "iam:DeleteRole"
             ],
             "Resource": "*"
         }
     ]
   }
   ```

1. [Create an access key for the user or role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
1. Save your access key and secret. You need these to authenticate AWS with GitLab.

## Configure your project

Use CI/CD environment variables to configure your project.

**Required configuration:**

1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Set the variable `AWS_ACCESS_KEY_ID` to your AWS access key ID.
1. Set the variable `AWS_SECRET_ACCESS_KEY` to your AWS secret access key.
1. Set the variable `TF_VAR_agent_token` to the agent token displayed in the previous task.
1. Set the variable `TF_VAR_kas_address` to the agent server address displayed in the previous task.

**Optional configuration:**

The file [`variables.tf`](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-eks/-/blob/main/variables.tf)
contains other variables that you can override according to your needs:

- `TF_VAR_region`: Set your cluster's region.
- `TF_VAR_cluster_name`: Set your cluster's name.
- `TF_VAR_cluster_version`: Set the version of Kubernetes.
- `TF_VAR_instance_type`: Set the instance type for the Kubernetes nodes.
- `TF_VAR_instance_count`: Set the number of Kubernetes nodes.
- `TF_VAR_agent_namespace`: Set the Kubernetes namespace for the GitLab agent.

View the [AWS Terraform provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) and the [Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) documentation for further resource options.

## Provision your cluster

After configuring your project, manually trigger the provisioning of your cluster. In GitLab:

1. On the left sidebar, go to **Build > Pipelines**.
1. Next to **Play** (**{play}**), select the dropdown list icon (**{chevron-lg-down}**).
1. Select **Deploy** to manually trigger the deployment job.

When the pipeline finishes successfully, you can view the new cluster:

- In AWS: From the [EKS console](https://console.aws.amazon.com/eks/home), select **Amazon EKS > Clusters**.
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
