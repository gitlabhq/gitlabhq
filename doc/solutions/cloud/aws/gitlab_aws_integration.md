---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Integrations Solutions Index for GitLab and AWS."
---

# Integrate with AWS

Learn how to integrate GitLab and AWS.

This content is intended for GitLab team members as well as members of the wider community.

This page attempts to index the ways in which GitLab can integrate with AWS. It does so whether the integration is the result of configuring general functionality, was built in to AWS or GitLab or is provided as a solution.

| Text Tag             | Configuration / Built / Solution                          | Support/Maintenance |
| -------------------- | ------------------------------------------------------------ | ------------------- |
| `[AWS Configuration]` | Integration via Configuring Existing AWS Functionality       | AWS                 |
| `[GitLab Configuration]` | Integration via Configuring Existing GitLab Functionality    | GitLab              |
| `[AWS Built]`     | Built into AWS by Product Team to Address AWS Integration    | AWS                 |
| `[GitLab Built]`  | Built into GitLab by Product Team to Address AWS Integration | GitLab              |
| `[AWS Solution]`     | Built as Solution Example by AWS or AWS Partners             | Community/Example   |
| `[GitLab Solution]`  | Built as Solution Example by GitLab or GitLab Partners       | Community/Example   |
| `[CI Solution]` | Built, at least in part, using GitLab CI and therefore <br />more customer customizable. | Items tagged `[CI Solution will]` <br />also carry one of the other tags <br />that indicates the maintenance status. |

## Integrations For Development Activities

### SCM Integrations

- **AWS CodeStar Connections** - enables SCM connections to multiple AWS Services. **Currently for GitLab.com SaaS only**. [Configure GitLab](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-gitlab.html). [Supported Providers](https://docs.aws.amazon.com/dtconsole/latest/userguide/supported-versions-connections.html). [Supported AWS Services](https://docs.aws.amazon.com/dtconsole/latest/userguide/integrations-connections.html) - each one may have to make updates to support GitLab, so here is the subset that currently support GitLab `[AWS Built]`
  - [AWS CodePipeline Integration](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html) - use GitLab as source for CodePipeline. `[AWS Built]`
  - **AWS CodeBuild Integration** - indirectly through CodePipeline support. `[AWS Built]`
  - **Amazon CodeWhisperer Customization Capability** [can connect to a GitLab repo](https://aws.amazon.com/blogs/aws/new-customization-capability-in-amazon-codewhisperer-generates-even-better-suggestions-preview/). `[AWS Built]`
  - **AWS Service Catalog** directly inherits CodeStar Connections, there is not any specific documentation about GitLab since it just uses any GitLab CodeStar Connection that has been created in the account.  `[AWS Built]`
  - **AWS Proton** directly inherits CodeStar Connections, there is not any specific documentation about GitLab since it just uses any GitLab CodeStar Connection that has been created in the account.  `[AWS Built]`
  - **AWS Glue Notebook Jobs** directly inherit CodeStar Connections, there is not any specific documentation about GitLab since it just uses any GitLab CodeStar Connection that has been created in the account.  `[AWS Built]`
  - **Amazon SageMaker MLOps Projects** are done in CodePipeline and so directly inherit CodeStar Connections ([as noted here](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-projects-walkthrough-3rdgit.html#sagemaker-proejcts-walkthrough-connect-3rdgit)), there is not any specific documentation about GitLab since it just uses any GitLab CodeStar Connection that has been created in the account.  `[AWS Built]`
  - **Amazon SageMaker Notebooks** [allow Git repositories to be specified by the Git clone URL](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-git-resource.html) and configuration of a secret - so GitLab is configurable. `[AWS Configuration]`
  - **AWS CloudFormation** publishing of public extensions - **not yet supported**. `[AWS Built]`
  - **Amazon CodeGuru Reviewer Repositories** - **not yet supported**. `[AWS Built]`
- [GitLab Push Mirroring to CodeCommit](../../../user/project/repository/mirror/push.md#set-up-a-push-mirror-from-gitlab-to-aws-codecommit) Workaround enables GitLab repositories to leverage CodePipeline SCM Triggers. GitLab can already leverage S3 and Container Triggers for CodePipeline. **Still required for Self-Managed and Dedicated for the time being.** `[GitLab Configuration]`

### CI Integrations

- **Direct CI Integrations That Use Keys, IAM or OIDC/JWT to Authenticate to AWS Services from GitLab Runners**
  - **Amazon CodeGuru Reviewer CI workflows using GitLab CI** - can be done, not yet documented. `[AWS Solution]` `[CI Solution]`
  - [Amazon CodeGuru Secure Scanning using GitLab CI](https://docs.aws.amazon.com/codeguru/latest/security-ug/get-started-gitlab.html)  `[AWS Solution]` `[CI Solution]`

### CD and Operations Integrations

- **AWS CodeDeploy Integration** - indirectly through CodePipeline support. `[AWS Built]`
- [Integrate EKS clusters for application deployment](../../../user/infrastructure/clusters/connect/new_eks_cluster.md). `[GitLab Built]`

## Solutions For Specific Development Frameworks and Ecosystems

Generally solutions demonstrate end-to-end capabilities for the development framework - leveraging all relevant integration techniques to show the art of maximum value for using GitLab and AWS together.

### Serverless Development

- [Serverless Framework Deployment to AWS with GitLab Serverless SAST Scanning and Managed DevOps Environments](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws) - working example code and tutorials. `[GitLab Solution]` `[CI Solution]`
  - [Tutorial: Serverless Framework Deployment to AWS with GitLab Serverless SAST Scanning](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/master/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [Tutorial: Secure Serverless Framework Development with GitLab Security Policy Approval Rules and Managed DevOps Environments](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/master/TUTORIAL2-SecurityAndManagedEnvs.md) `[GitLab Solution]` `[CI Solution]`

### Infrastructure as Code

- [Terraform Deployment to AWS with GitLab MR Managed DevOps Environments](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster)
  - [Tutorial: Terraform Deployment to AWS with GitLab IaC SAST Scanning](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [Terraform Deployment to AWS with GitLab Security Policy Approval Rules and Managed DevOps Environments](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL2-SecurityAndManagedEnvs.md) `[GitLab Solution]` `[CI Solution]`
- [Tutorial: CloudFormation Deployment With GitLab MR Managed DevOps Environments](https://gitlab.com/guided-explorations/aws/cloudformation-deploy) `[GitLab Solution]` `[CI Solution]`

### .Net on AWS

- [Working Example Code for Scaling .NET Framework 4.x Runners on AWS](https://gitlab.com/guided-explorations/aws/dotnet-aws-toolkit)  `[GitLab Solution]` `[CI Solution]`
- [Video Walkthrough of Code and Building a .NET Framework 4.x Project](https://www.youtube.com/watch?v=_4r79ZLmDuo)  `[GitLab Solution]` `[CI Solution]`

## Authentication Integration

- [Runner Job Authentication using Open ID & JWT Authentication](../../../ci/cloud_services/aws/index.md). `[GitLab Built]`
  - [Configure OpenID Connect between GitLab and AWS](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws) `[GitLab Solution]` `[CI Solution]`
  - [OIDC and Multi-Account Deployment with GitLab and ECS](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs) `[GitLab Solution]` `[CI Solution]`

## GitLab Instance Compute & Operations Integration

- Installing GitLab Self-Managed on AWS
  - GitLab Single EC2 Instance. `[GitLab Built]`
    - [Using 5 Seat AWS marketplace subscription](gitlab_single_box_on_aws.md#marketplace-subscription)
    - [Using Prepared AMIs](gitlab_single_box_on_aws.md#official-gitlab-releases-as-amis) - Bring Your Own License for Enterprise Edition.

  - GitLab Cloud Native Hybrid Scaled on AWS EKS and Paas. `[GitLab Built]`
    - Using GitLab Environment Toolkit (GET) - `[GitLab Solution]`

  - GitLab Instance Scaled on AWS EC2 and PaaS. `[GitLab Built]`
    - Using GitLab Environment Toolkit (GET) - `[GitLab Solution]`

- [Amazon Managed Grafana](https://docs.aws.amazon.com/grafana/latest/userguide/gitlab-AMG-datasource.html) for GitLab self-managed Prometheus metrics. `[AWS Built]`

## GitLab Runner on AWS Compute

- [Autoscaling GitLab Runner on AWS EC2](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/). `[GitLab Built]`
- [GitLab HA Scaling Runner Vending Machine for AWS EC2 ASG](https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/). `[GitLab Solution]`
  - Runner vending machine training resources.

- [GitLab EKS Fargate Runners](https://gitlab.com/guided-explorations/aws/eks-runner-configs/gitlab-runner-eks-fargate/-/blob/main/README.md). `[GitLab Solution]`
