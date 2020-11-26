---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Adding EKS clusters

GitLab supports adding new and existing EKS clusters.

## EKS requirements

Before creating your first cluster on Amazon EKS with GitLab's integration, make sure the following
requirements are met:

- An [Amazon Web Services](https://aws.amazon.com/) account is set up and you are able to log in.
- You have permissions to manage IAM resources.
- If you want to use an [existing EKS cluster](#existing-eks-cluster):
  - An Amazon EKS cluster with worker nodes properly configured.
  - `kubectl` [installed and configured](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#get-started-kubectl)
    for access to the EKS cluster.

### Additional requirements for self-managed instances **(CORE ONLY)**

If you are using a self-managed GitLab instance, GitLab must first be configured with a set of
Amazon credentials. These credentials are used to assume an Amazon IAM role provided by the user
creating the cluster. Create an IAM user and ensure it has permissions to assume the role(s) that
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

Generate an access key for the IAM user, and configure GitLab with the credentials:

1. Navigate to **Admin Area > Settings > General** and expand the **Amazon EKS** section.
1. Check **Enable Amazon EKS integration**.
1. Enter the account ID and access key credentials into the respective
   `Account ID`, `Access key ID` and `Secret access key` fields.
1. Click **Save changes**.

## New EKS cluster

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22392) in GitLab 12.5.

To create and add a new Kubernetes cluster to your project, group, or instance:

1. Navigate to your:
   - Project's **Operations > Kubernetes** page, for a project-level cluster.
   - Group's **Kubernetes** page, for a group-level cluster.
   - **Admin Area > Kubernetes**, for an instance-level cluster.
1. Click **Add Kubernetes cluster**.
1. Under the **Create new cluster** tab, click **Amazon EKS** to display an
   `Account ID` and `External ID` needed for later steps.
1. In the [IAM Management Console](https://console.aws.amazon.com/iam/home), create an IAM policy:
   1. From the left panel, select **Policies**.
   1. Click **Create Policy**, which opens a new window.
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
                      "iam:ListRoles",
                      "iam:PassRole",
                      "ssm:GetParameters"
                  ],
                  "Resource": "*"
              }
          ]
      }
      ```

      If an error is encountered during the creation process, changes will
      not be rolled back and you must remove resources manually. You can do this by deleting
      the relevant [CloudFormation stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-delete-stack.html)

   1. Click **Review policy**.
   1. Enter a suitable name for this policy, and click **Create Policy**. You can now close this window.

1. In the [IAM Management Console](https://console.aws.amazon.com/iam/home), create an EKS management IAM role.
   To do so, follow the [Amazon EKS cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) instructions
   to create a IAM role suitable for managing the AWS EKS cluster's resources on your behalf.
   In addition to the policies that guide suggests, you must also include the `AmazonEKSClusterPolicy`
   policy for this role in order for GitLab to manage the EKS cluster correctly.
1. In the [IAM Management Console](https://console.aws.amazon.com/iam/home), create an IAM role:
   1. From the left panel, select **Roles**.
   1. Click **Create role**.
   1. Under `Select type of trusted entity`, select **Another AWS account**.
   1. Enter the Account ID from GitLab into the `Account ID` field.
   1. Check **Require external ID**.
   1. Enter the External ID from GitLab into the `External ID` field.
   1. Click **Next: Permissions**, and select the policy you just created.
   1. Click **Next: Tags**, and optionally enter any tags you wish to associate with this role.
   1. Click **Next: Review**.
   1. Enter a role name and optional description into the fields provided.
   1. Click **Create role**, the new role name displays at the top. Click on its name and copy the `Role ARN` from the newly created role.
1. In GitLab, enter the copied role ARN into the `Role ARN` field.
1. In the **Cluster Region** field, enter the [region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) you plan to use for your new cluster. GitLab confirms you have access to this region when authenticating your role.
1. Click **Authenticate with AWS**.
1. Choose your cluster's settings:
   - **Kubernetes cluster name** - The name you wish to give the cluster.
   - **Environment scope** - The [associated environment](index.md#setting-the-environment-scope) to this cluster.
   - **Kubernetes version** - The [Kubernetes version](index.md#supported-cluster-versions) to use.
   - **Service role** - Select the **EKS IAM role** you created earlier to allow Amazon EKS
     and the Kubernetes control plane to manage AWS resources on your behalf.

     NOTE: **Note:**
     This IAM role is _not_ the IAM role you created in the previous step. It should be
     the one you created much earlier by following the
     [Amazon EKS cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)
     guide.
   - **Key pair name** - Select the [key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
     that you can use to connect to your worker nodes if required.
   - **VPC** - Select a [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
     to use for your EKS Cluster resources.
   - **Subnets** - Choose the [subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
     in your VPC where your worker nodes run. You must select at least two.
   - **Security group** - Choose the [security group](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
     to apply to the EKS-managed Elastic Network Interfaces that are created in your worker node subnets.
   - **Instance type** - The [instance type](https://aws.amazon.com/ec2/instance-types/) of your worker nodes.
   - **Node count** - The number of worker nodes.
   - **GitLab-managed cluster** - Leave this checked if you want GitLab to manage namespaces and service accounts for this cluster.
     See the [Managed clusters section](index.md#gitlab-managed-clusters) for more information.
1. Finally, click the **Create Kubernetes cluster** button.

After about 10 minutes, your cluster is ready to go. You can now proceed
to install some [pre-defined applications](index.md#installing-applications).

NOTE: **Note:**
You must add your AWS external ID to the
[IAM Role in the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html#cli-configure-role-xaccount)
to manage your cluster using `kubectl`.

### Troubleshooting creating a new cluster

The following errors are commonly encountered when creating a new cluster.

#### Error: Request failed with status code 422

When submitting the initial authentication form, GitLab returns a status code 422
error when it can't determine the role or region you've provided. Make sure you've
correctly configured your role with the **Account ID** and **External ID**
provided by GitLab. In GitLab, make sure to enter the correct **Role ARN**.
Make sure you also have access to the chosen region.

#### Could not load Security Groups for this VPC

When populating options in the configuration form, GitLab returns this error
because GitLab has successfully assumed your provided role, but the role has
insufficient permissions to retrieve the resources needed for the form. Make sure
you've assigned the role the correct permissions.

#### `ROLLBACK_FAILED` during cluster creation

The creation process halted because GitLab encountered an error when creating
one or more resources. You can inspect the associated
[CloudFormation stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-view-stack-data-resources.html)
to find the specific resources that failed to create.

If the `Cluster` resource failed with the error
`The provided role doesn't have the Amazon EKS Managed Policies associated with it.`,
the role specified in **Role name** is not configured correctly.

NOTE: **Note:**
This role should be the role you created by following the
[EKS cluster IAM role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html) guide.
In addition to the policies that guide suggests, you must also include the
`AmazonEKSClusterPolicy` policy for this role in order for GitLab to manage the EKS cluster correctly.

## Existing EKS cluster

For information on adding an existing EKS cluster, see
[Existing Kubernetes cluster](add_remove_clusters.md#existing-kubernetes-cluster).

### Create a default Storage Class

Amazon EKS doesn't have a default Storage Class out of the box, which means
requests for persistent volumes are not automatically fulfilled. As part
of Auto DevOps, the deployed PostgreSQL instance requests persistent storage,
and without a default storage class it cannot start.

If a default Storage Class doesn't already exist and is desired, follow Amazon's
[guide on storage classes](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html)
to create one.

Alternatively, disable PostgreSQL by setting the project variable
[`POSTGRES_ENABLED`](../../../topics/autodevops/customize.md#environment-variables) to `false`.

### Deploy the app to EKS

With RBAC disabled and services deployed,
[Auto DevOps](../../../topics/autodevops/index.md) can now be leveraged
to build, test, and deploy the app.

[Enable Auto DevOps](../../../topics/autodevops/index.md#at-the-project-level)
if not already enabled. If a wildcard DNS entry was created resolving to the
Load Balancer, enter it in the `domain` field under the Auto DevOps settings.
Otherwise, the deployed app isn't externally available outside of the cluster.

![Deploy Pipeline](img/pipeline.png)

GitLab creates a new pipeline, which begins to build, test, and deploy the app.

After the pipeline has finished, your app runs in EKS, and is available
to users. Click on **CI/CD > Environments**.

![Deployed Environment](img/environment.png)

GitLab displays a list of the environments and their deploy status, as well as
options to browse to the app, view monitoring metrics, and even access a shell
on the running pod.
