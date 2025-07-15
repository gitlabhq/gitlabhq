---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Connect EKS clusters through cluster certificates (deprecated)
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

This feature was deprecated in GitLab 14.5. Use [Infrastructure as Code](../../infrastructure/iac/_index.md)
to create new clusters.

{{< /alert >}}

Through GitLab, you can create new clusters and add existing clusters hosted on Amazon Elastic
Kubernetes Service (EKS).

## Connect an existing EKS cluster

If you already have an EKS cluster and want to connect it to GitLab,
use the [GitLab agent for Kubernetes](../../clusters/agent/_index.md).

## Create a new EKS cluster

To create a new cluster from GitLab, use [Infrastructure as Code](../../infrastructure/iac/_index.md).

### How to create a new cluster on EKS through cluster certificates (deprecated)

{{< history >}}

- [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/327908) in GitLab 14.0.

{{< /history >}}

Prerequisites:

- An [Amazon Web Services](https://aws.amazon.com/) account.
- Permissions to manage IAM resources.

For instance-level clusters, see [additional requirements for self-managed instances](#additional-requirements-for-self-managed-instances).

To create new Kubernetes clusters for your project, group, or instance through the certificate-based method:

1. [Define the access control (RBAC or ABAC) for your cluster](cluster_access.md).
1. [Create a cluster in GitLab](#create-a-new-eks-cluster-in-gitlab).
1. [Prepare the cluster in Amazon](#prepare-the-cluster-in-amazon).
1. [Configure your cluster's data in GitLab](#configure-your-clusters-data-in-gitlab).

Further steps:

1. [Create a default Storage Class](#create-a-default-storage-class).
1. [Deploy the app to EKS](#deploy-the-app-to-eks).

#### Create a new EKS cluster in GitLab

To create new a EKS cluster for your project, group, or instance, through
cluster certificates:

1. Go to your:
   - Project's **Operate > Kubernetes clusters** page, for a project-level cluster.
   - Group's **Kubernetes** page, for a group-level cluster.
   - The **Admin** area's **Kubernetes** page, for an instance-level cluster.
1. Select **Integrate with a cluster certificate**.
1. Under the **Create new cluster** tab, select **Amazon EKS** to display an
   `Account ID` and `External ID` needed for later steps.
1. In the [IAM Management Console](https://console.aws.amazon.com/iam/home), create an IAM policy:
   1. From the left panel, select **Policies**.
   1. Select **Create Policy**, which opens a new window.
   1. Select the **JSON** tab, and paste the following snippet in place of the
      existing content. These permissions give GitLab the ability to create
      resources, but not delete them:

      ```json
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": [
                      "autoscaling:CreateAutoScalingGroup",
                      "autoscaling:DescribeAutoScalingGroups",
                      "autoscaling:DescribeScalingActivities",
                      "autoscaling:UpdateAutoScalingGroup",
                      "autoscaling:CreateLaunchConfiguration",
                      "autoscaling:DescribeLaunchConfigurations",
                      "cloudformation:CreateStack",
                      "cloudformation:DescribeStacks",
                      "ec2:AuthorizeSecurityGroupEgress",
                      "ec2:AuthorizeSecurityGroupIngress",
                      "ec2:RevokeSecurityGroupEgress",
                      "ec2:RevokeSecurityGroupIngress",
                      "ec2:CreateSecurityGroup",
                      "ec2:createTags",
                      "ec2:DescribeImages",
                      "ec2:DescribeKeyPairs",
                      "ec2:DescribeRegions",
                      "ec2:DescribeSecurityGroups",
                      "ec2:DescribeSubnets",
                      "ec2:DescribeVpcs",
                      "eks:CreateCluster",
                      "eks:DescribeCluster",
                      "iam:AddRoleToInstanceProfile",
                      "iam:AttachRolePolicy",
                      "iam:CreateRole",
                      "iam:CreateInstanceProfile",
                      "iam:CreateServiceLinkedRole",
                      "iam:GetRole",
                      "iam:listAttachedRolePolicies",
                      "iam:ListRoles",
                      "iam:PassRole",
                      "ssm:GetParameters"
                  ],
                  "Resource": "*"
              }
          ]
      }
      ```

      If you get an error during this process, GitLab does not roll back the changes. You must remove resources manually. You can do this by deleting
      the relevant [CloudFormation stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html).

   1. Select **Review policy**.
   1. Enter a suitable name for this policy, and select **Create Policy**. You can now close this window.

### Prepare the cluster in Amazon

1. [Create an **EKS IAM role** for your cluster](#create-an-eks-iam-role-for-your-cluster) (**role A**).
1. [Create **another EKS IAM role** for GitLab authentication with Amazon](#create-another-eks-iam-role-for-gitlab-authentication-with-amazon) (**role B**).

#### Create an EKS IAM role for your cluster

In the [IAM Management Console](https://console.aws.amazon.com/iam/home),
create an **EKS IAM role** (**role A**) following the [Amazon EKS cluster IAM role instructions](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html).
This role is necessary so that Kubernetes clusters managed by Amazon EKS can make calls to other AWS
services on your behalf to manage the resources that you use with the service.

For GitLab to manage the EKS cluster correctly, you must include `AmazonEKSClusterPolicy` in
addition to the policies the guide suggests.

#### Create another EKS IAM role for GitLab authentication with Amazon

In the [IAM Management Console](https://console.aws.amazon.com/iam/home),
create another IAM role (**role B**) for GitLab authentication with AWS:

1. On the AWS IAM console, select **Roles** from the left panel.
1. Select **Create role**.
1. Under **Select type of trusted entity**, select **Another AWS account**.
1. Enter the Account ID from GitLab into the **Account ID** field.
1. Check **Require external ID**.
1. Enter the External ID from GitLab into the **External ID** field.
1. Select **Next: Permissions**, and select the policy you just created.
1. Select **Next: Tags**, and optionally enter any tags you wish to associate with this role.
1. Select **Next: Review**.
1. Enter a role name and optional description into the fields provided.
1. Select **Create role**. The new role name displays at the top. Select its name and copy the
   `Role ARN` from the newly created role.

### Configure your cluster's data in GitLab

1. Back in GitLab, enter the copied role ARN into the **Role ARN** field.
1. In the **Cluster Region** field, enter the [region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) you plan to use for your new cluster. GitLab confirms you have access to this region when authenticating your role.
1. Select **Authenticate with AWS**.
1. Adjust your [cluster's settings](#cluster-settings).
1. Select the **Create Kubernetes cluster** button.

After about 10 minutes, your cluster is ready to go.

{{< alert type="note" >}}

If you have [installed and configured](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#get-started-kubectl) `kubectl` and you would like to manage your cluster with it, you must add your AWS external ID in the AWS configuration. For more information on how to configure AWS CLI, see [using an IAM role in the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html#cli-configure-role-xaccount).

{{< /alert >}}

#### Cluster settings

When you create a new cluster, you have the following settings:

| Setting                 | Description |
| ----------------------- |------------ |
| Kubernetes cluster name | Your cluster's name. |
| Environment scope       | The [associated environment](multiple_kubernetes_clusters.md#setting-the-environment-scope). |
| Service role            | The **EKS IAM role** (**role A**). |
| Kubernetes version      | The [Kubernetes version](../../clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) for your cluster. |
| Key pair name           | The [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) that you can use to connect to your worker nodes. |
| VPC                     | The [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) to use for your EKS Cluster resources. |
| Subnets                 | The [subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html) in your VPC where your worker nodes run. Two are required. |
| Security group          | The [security group](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html) to apply to the EKS-managed Elastic Network Interfaces that are created in your worker node subnets. |
| Instance type           | The [instance type](https://aws.amazon.com/ec2/instance-types/) of your worker nodes. |
| Node count              | The number of worker nodes. |
| GitLab-managed cluster  | Check if you want GitLab to manage namespaces and service accounts for this cluster. |

## Create a default Storage Class

Amazon EKS doesn't have a default Storage Class out of the box, which means
requests for persistent volumes are not automatically fulfilled. As part
of Auto DevOps, the deployed PostgreSQL instance requests persistent storage,
and without a default storage class it cannot start.

To create a default storage class if one doesn't already exist, see [Storage Classes](https://docs.aws.amazon.com/eks/latest/userguide/storage.html#storage-classes).

Alternatively, disable PostgreSQL by setting the project variable
[`POSTGRES_ENABLED`](../../../topics/autodevops/cicd_variables.md) to `false`.

## Deploy the app to EKS

With RBAC disabled and services deployed,
[Auto DevOps](../../../topics/autodevops/_index.md) can now be leveraged
to build, test, and deploy the app.

[Enable Auto DevOps](../../../topics/autodevops/_index.md#per-project)
if not already enabled. If a wildcard DNS entry was created resolving to the
Load Balancer, enter it in the `domain` field under the Auto DevOps settings.
Otherwise, the deployed app isn't externally available outside of the cluster.

![Deploy Pipeline](img/pipeline_v11_0.png)

GitLab creates a new pipeline, which begins to build, test, and deploy the app.

After the pipeline has finished, your app runs in EKS, and is available
to users. Select **Operate > Environments**.

![Deployed Environment](img/environment_v11_0.png)

GitLab displays a list of the environments and their deploy status, as well as
options to browse to the app, view monitoring metrics, and even access a shell
on the running pod.

## Additional requirements for self-managed instances

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If you are using GitLab Self-Managed, you need to configure
Amazon credentials. GitLab uses these credentials to assume an Amazon IAM role to create your cluster.

Create an IAM user and ensure it has permissions to assume the roles that
your users need to create EKS clusters.

For example, the following policy document allows assuming a role whose name starts with
`gitlab-eks-` in account `123456789012`:

```json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": "arn:aws:iam::123456789012:role/gitlab-eks-*"
  }
}
```

### Configure Amazon authentication

To configure Amazon authentication in GitLab, generate an access key for the
IAM user in the Amazon AWS console, and follow these steps:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Amazon EKS**.
1. Check **Enable Amazon EKS integration**.
1. Enter your **Account ID**.
1. Enter your [access key and ID](#eks-access-key-and-id).
1. Select **Save changes**.

#### EKS access key and ID

You can use instance profiles to dynamically retrieve temporary credentials from AWS when needed.
In this case, leave the `Access key ID` and `Secret access key` fields blank
and [pass an IAM role to an EC2 instance](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html).

Otherwise, enter your access key credentials into **Access key ID** and **Secret access key**.

## Troubleshooting

The following errors are commonly encountered when creating a new cluster.

### Validation failed: Role ARN must be a valid Amazon Resource Name

Check that the `Provision Role ARN` is correct. An example of a valid ARN:

```plaintext
arn:aws:iam::123456789012:role/gitlab-eks-provision'
```

### Access denied: User is not authorized to perform: `sts:AssumeRole` on resource: `arn:aws:iam::y`

This error occurs when the credentials defined in the
[Configure Amazon authentication](#configure-amazon-authentication) cannot assume the role defined by the
Provision Role ARN:

```plaintext
User `arn:aws:iam::x` is not authorized to perform: `sts:AssumeRole` on resource: `arn:aws:iam::y`
```

Check that:

1. The initial set of AWS credentials [has the AssumeRole policy](#additional-requirements-for-self-managed-instances).
1. The Provision Role has access to create clusters in the given region.
1. The account ID and
   [external ID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html)
   match the value defined in the **Trust relationships** tab in AWS:

   ![AWS IAM Trust relationships](img/aws_iam_role_trust_v13_7.png)

### Could not load Security Groups for this VPC

When populating options in the configuration form, GitLab returns this error
because GitLab has successfully assumed your provided role, but the role has
insufficient permissions to retrieve the resources needed for the form. Make sure
you've assigned the role the correct permissions.

### Key Pairs are not loaded

GitLab loads the key pairs from the **Cluster Region** specified. Ensure that key pair exists in that region.

#### `ROLLBACK_FAILED` during cluster creation

The creation process halted because GitLab encountered an error when creating
one or more resources. You can inspect the associated
[CloudFormation stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-view-stack-data-resources.html)
to find the specific resources that failed to create.

If the `Cluster` resource failed with the error
`The provided role doesn't have the Amazon EKS Managed Policies associated with it.`,
the role specified in **Role name** is not configured correctly.

{{< alert type="note" >}}

This role should be the role you created by following the
[EKS cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) guide.
In addition to the policies that guide suggests, you must also include the
`AmazonEKSClusterPolicy` policy for this role in order for GitLab to manage the EKS cluster correctly.

{{< /alert >}}
