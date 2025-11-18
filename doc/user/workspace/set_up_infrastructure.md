---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create the infrastructure needed to support GitLab Workspaces for on-demand, cloud-based development environments.
title: 'Tutorial: Set up workspaces infrastructure on AWS'
---

<!-- vale gitlab_base.FutureTense = NO -->

This tutorial guides you through the GitLab workspaces infrastructure setup on AWS using
[OpenTofu](https://opentofu.org/), an open-source fork of Terraform through Infrastructure as Code (IaC).

## Before you begin

To follow this tutorial, you must have:

- An Amazon Web Services (AWS) account.
- A domain name for your workspaces environment.

To set up GitLab workspaces infrastructure:

1. [Fork the repository](#fork-the-repository)
1. [Set up AWS credentials](#set-up-aws-credentials)
1. [Prepare domain and certificates](#prepare-domain-and-certificates)
1. [Create required keys](#create-required-keys)
1. [Create a GitLab Agent for Kubernetes token](#create-a-gitlab-agent-for-kubernetes-token)
1. [Configure GitLab OAuth](#configure-gitlab-oauth)
1. [Configure CI/CD variables](#configure-cicd-variables)
1. [Update the GitLab agent for Kubernetes configuration](#update-the-gitlab-agent-for-kubernetes-configuration)
1. [Run the pipeline](#run-the-pipeline)
1. [Configure DNS records](#configure-dns-records)
1. [Authorize the agent](#authorize-the-agent)
1. [Create a workspace and verify setup](#create-a-workspace-and-verify-setup)

## Fork the repository

First, you need to create your own copy of the infrastructure setup repository so that you can
configure it for your environment.

{{< alert type="note" >}}

It is not possible to create workspaces from projects in your personal namespace. Instead, fork the
repository to a top-level group or subgroup.

{{< /alert >}}

To fork the repository:

1. Go to the [Workspaces Infrastructure Setup AWS](https://gitlab.com/gitlab-org/workspaces/examples/workspaces-infrastructure-setup-aws) repository.
1. Create a fork of the repository. For more information, see [Create a fork](../project/repository/forking_workflow.md#create-a-fork).

## Set up AWS credentials

Next, set up the necessary permissions in AWS so the infrastructure can be properly provisioned.

To set up AWS credentials:

1. Create an [IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html) or
[IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html).
1. Assign the following permissions:

   ```json
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
           "kms:TagResource",
           "kms:UntagResource",
           "kms:ListResourceTags",
           "kms:CreateKey",
           "kms:CreateAlias",
           "kms:ListAliases",
           "kms:DeleteAlias",
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
           "iam:DetachRolePolicy",
           "iam:ListInstanceProfilesForRole",
           "iam:DeleteRole",
           "iam:CreateOpenIDConnectProvider",
           "iam:CreatePolicy",
           "iam:TagOpenIDConnectProvider",
           "iam:GetPolicy",
           "iam:GetPolicyVersion",
           "iam:GetOpenIDConnectProvider",
           "iam:DeleteOpenIDConnectProvider",
           "iam:ListPolicyVersions",
           "iam:DeletePolicy"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

1. [Create an access key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
for the user or role.
1. Save your access key ID and secret access key. You'll need them when configuring CI/CD variables later.

## Prepare domain and certificates

For your workspaces to be accessible, you'll need a domain and TLS certificates to secure the
connections.

To prepare your domain and certificates:

1. Buy a domain or use an existing domain for your workspaces environment.
1. Create TLS certificates for:
   - GitLab Workspaces Proxy Domain. For example, `workspaces.example.dev`.
   - GitLab Workspaces Proxy Wildcard Domain. For example, `*.workspaces.example.dev`.

For more information, see [Generate TLS certificates](set_up_gitlab_agent_and_proxies.md#generate-tls-certificates).

## Create required keys

Now you need to create security keys for authentication and SSH connections.

To create the required keys:

1. Generate a signing key consisting of random letters, numbers, and special characters.
For example, run:

   ```shell
   openssl rand -base64 32
   ```

1. Generate an SSH host key:

   ```shell
   ssh-keygen -f ssh-host-key -N '' -t rsa
   ```

## Create a GitLab agent for Kubernetes token

The GitLab agent for Kubernetes connects your AWS Kubernetes cluster to GitLab.

To create a token for the agent:

1. Go to your group.
1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Operate** > **Kubernetes clusters**.
1. Select **Connect a cluster**.
1. Enter a name for your agent and save for later use. For example, `gitlab-workspaces-agentk-eks`.
1. Select **Create and register**.
1. Save the token and KAS address for later use.
1. Select **Continue**.

## Configure GitLab OAuth

Next, set up OAuth authentication to securely access workspaces.

To configure GitLab OAuth:

1. Go to **User settings**:
   1. Select your profile picture, then select **Preferences**.
1. On the left sidebar, select **Applications**.
1. Scroll down to **OAuth applications**.
1. Select **Add new application**.
1. Update the following settings:

   - Name: GitLab Workspaces Proxy
   - Redirect URI: For example, `https://workspaces.example.dev/auth/callback`. Replace with your
     user-defined domain.
   - Select the **Confidential** checkbox.
   - Scopes: `api`, `read_user`, `openid`, and `profile`.

1. Select **Save application**.
1. Save the **Application ID** and **Secret** for your CI/CD variables.
1. Select **Continue**.

## Configure CI/CD variables

Now, you need to add the necessary variables to your CI/CD configuration so the infrastructure
pipeline can run.

To configure CI/CD variables:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **CI/CD**.
1. Expand **Variables**.
1. In the **Project variables** section, add the following required variables:

   | Variable                                       | Value |
   |------------------------------------------------|-------|
   | `AWS_ACCESS_KEY_ID`                            | AWS access key ID. |
   | `AWS_SECRET_ACCESS_KEY`                        | AWS secret access key. |
   | `TF_VAR_agent_token`                           | GitLab agent for Kubernetes token. |
   | `TF_VAR_kas_address`                           | GitLab Kubernetes Agent Server address. Required if on a GitLab Self-Managed instance. For example, `wss://kas.gitlab.com`. |
   | `TF_VAR_workspaces_proxy_auth_client_id`       | OAuth application client ID. |
   | `TF_VAR_workspaces_proxy_auth_client_secret`   | OAuth application secret. |
   | `TF_VAR_workspaces_proxy_auth_redirect_uri`    | OAuth callback URL. For example, `https://workspaces.example.dev/auth/callback`. |
   | `TF_VAR_workspaces_proxy_auth_signing_key`     | Your generated signing key. |
   | `TF_VAR_workspaces_proxy_domain`               | Domain for the workspaces proxy. |
   | `TF_VAR_workspaces_proxy_domain_cert`          | TLS certificate for the proxy domain. |
   | `TF_VAR_workspaces_proxy_domain_key`           | TLS key for the proxy domain. |
   | `TF_VAR_workspaces_proxy_ssh_host_key`         | Your generated SSH host key. |
   | `TF_VAR_workspaces_proxy_wildcard_domain`      | Wildcard domain for workspaces. |
   | `TF_VAR_workspaces_proxy_wildcard_domain_cert` | TLS certificate for the wildcard domain. |
   | `TF_VAR_workspaces_proxy_wildcard_domain_key`  | TLS key for the wildcard domain. |

1. Optional. Add any of these variables to customize your deployment:

   | Variable                                     | Value |
   |----------------------------------------------|-------|
   | `TF_VAR_region`                              | AWS region. |
   | `TF_VAR_zones`                               | AWS availability zones. |
   | `TF_VAR_name`                                | Name prefix for resources. |
   | `TF_VAR_cluster_endpoint_public_access`      | Public access to cluster endpoint. |
   | `TF_VAR_cluster_node_instance_type`          | EC2 instance type for Kubernetes nodes. |
   | `TF_VAR_cluster_node_count_min`              | Minimum number of worker nodes. |
   | `TF_VAR_cluster_node_count_max`              | Maximum number of worker nodes. |
   | `TF_VAR_cluster_node_count`                  | Number of worker nodes. |
   | `TF_VAR_cluster_node_labels`                 | Map of labels to apply on the cluster nodes. |
   | `TF_VAR_agent_namespace`                     | Kubernetes namespace for the agent. |
   | `TF_VAR_workspaces_proxy_namespace`          | Kubernetes namespace for workspaces proxy. |
   | `TF_VAR_workspaces_proxy_ingress_class_name` | Ingress class name. |
   | `TF_VAR_ingress_nginx_namespace`             | Kubernetes namespace for Ingress-NGINX. |

Great job! You've configured all the necessary variables for your infrastructure deployment.

## Update the GitLab agent for Kubernetes configuration

Now, you need to configure the GitLab agent for Kubernetes to support workspaces.

To update the agent configuration:

1. In your forked repository, open the `.gitlab/agents/gitlab-workspaces-agentk-eks/config.yaml` file.

   {{< alert type="note" >}}

   The directory that contains the `config.yaml` file must match the agent name you created in the
   [Create a GitLab agent for Kubernetes token](#create-a-gitlab-agent-for-kubernetes-token) step.

   {{< /alert >}}

1. Update the file with the following required fields:

   ```yaml
   remote_development:
     enabled: true
     dns_zone: "workspaces.example.dev"  # Replace with your domain
   ```

   For more configuration options, see [Workspace settings](settings.md).

1. Commit and push these changes to your repository.

## Run the pipeline

It's time to deploy your infrastructure. You'll run the CI/CD pipeline to create all the necessary
resources in AWS.

To run the pipeline:

1. Create a new pipeline in your GitLab project:
   1. On the left sidebar, select **Build** > **Pipelines**.
   1. Select **New pipeline** and select **New pipeline** again to confirm.
1. Verify the `plan` job succeeds, then manually trigger the `apply` job.

When the OpenTofu code runs, it creates these resources in AWS:

- A Virtual Private Cloud (VPC).
- An Elastic Kubernetes Service (EKS) cluster.
- A GitLab agent for Kubernetes Helm release.
- A GitLab Workspaces Proxy Helm release.
- An Ingress NGINX Helm release.

Excellent! Your infrastructure is now being deployed. This might take some time to complete.

## Configure DNS records

Now that your infrastructure is deployed, you need to configure DNS records to point to your new
environment.

To configure DNS records:

1. Get the Ingress-NGINX load balancer address from the pipeline output:

   ```shell
   kubectl get services -n ingress-nginx ingress-nginx-controller
   ```

1. Create DNS records that point your domains to this address. For example:
   - `workspaces.example.dev` → Load balancer IP address
   - `*.workspaces.example.dev` → Load balancer IP address

## Authorize the agent

Next, you'll authorize the GitLab agent for Kubernetes to connect to your GitLab instance.

To authorize the agent:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Workspaces**.
1. In the **Group agents** section, select the **All agents** tab.
1. From the list of available agents, find the agent with status **Blocked**, and select **Allow**.
1. On the confirmation dialog, select **Allow agent**.

## Create a workspace and verify setup

Finally, let's make sure everything is working correctly by creating a test workspace.

To verify your workspace setup:

1. Create a new workspace by following the steps in [Create a workspace](configuration.md#create-a-workspace).
1. From your project, select **Code**.
1. Select your workspace name.
1. Interact with the workspace by opening the Web IDE, accessing the terminal, or making changes to project files.

Congratulations! You've successfully set up GitLab workspaces infrastructure on AWS. Your users
can now create development workspace environments for their projects.

If you encounter any issues, check the logs for additional details and refer to
[Troubleshooting workspaces](workspaces_troubleshooting.md) for guidance.

## Related topics

- [Workspaces](_index.md)
- [Configure workspaces](configuration.md)
- [Workspace settings](settings.md)
- [Tutorial: Create a custom workspace image that supports arbitrary user IDs](create_image.md)
