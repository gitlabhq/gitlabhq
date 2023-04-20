---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

{::options parse_block_html="true" /}

# Provision GitLab Cloud Native Hybrid on AWS EKS **(FREE SELF)**

GitLab "Cloud Native Hybrid" is a hybrid of the cloud native technology Kubernetes (EKS) and EC2. While as much of the GitLab application as possible runs in Kubernetes or on AWS services (PaaS), the GitLab service Gitaly must still be run on EC2. Gitaly is a layer designed to overcome limitations of the Git binaries in a horizontally scaled architecture. You can read more here about why Gitaly was built and why the limitations of Git mean that it must currently run on instance compute in [Git Characteristics That Make Horizontal Scaling Difficult](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-characteristics-that-make-horizontal-scaling-difficult).

Amazon provides a managed Kubernetes service offering known as [Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/).

## Tested AWS Bill of Materials by reference architecture size

| GitLab Cloud Native Hybrid Ref Arch                          | GitLab Baseline Performance Test Results Omnibus on Instances       | AWS Bill of Materials (BOM) for CNH                          | AWS Build Performance Testing Results for [CNH](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/5K/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128_results.txt) | CNH Cost Estimate 3 AZs*                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [2K Omnibus](../../administration/reference_architectures/2k_users.md) | [2K Baseline](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/2k) | [2K Cloud Native Hybrid on EKS](#2k-cloud-native-hybrid-on-eks) | GPT Test Results                                             | [1 YR Ec2 Compute Savings + 1 YR RDS & ElastiCache RIs](https://calculator.aws/#/estimate?id=544bcf1162beae6b8130ad257d081cdf9d4504e3)<br />(2 AZ Cost Estimate is in BOM Below) |
| [3K](../../administration/reference_architectures/3k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) | [3k Baseline](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/3k) | [3K Cloud Native Hybrid on EKS](#3k-cloud-native-hybrid-on-eks) | [3K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/3K/3k-QuickStart-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_124216/3k-QuickStart-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_124216_results.txt)<br /><br />[3K Elastic Auto Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/3K/3k-QuickStart-AutoScale-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_194200/3k-QuickStart-AutoScale-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_194200_results.txt) | [1 YR Ec2 Compute Savings + 1 YR RDS & ElastiCache RIs](https://calculator.aws/#/estimate?id=f1294fec554e21be999711cddcdab9c5e7f83f14)<br />(2 AZ Cost Estimate is in BOM Below) |
| [5K](../../administration/reference_architectures/5k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) | [5k Baseline](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/5k) | [5K Cloud Native Hybrid on EKS](#5k-cloud-native-hybrid-on-eks) | [5K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/5K/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128_results.txt)<br /><br />[5K AutoScale from 25% GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/5K/5k-QuickStart-AutoScale-From-25Percent-ARM-RDS-Redis_v13-12-3-ee_2021-07-24_102717/5k-QuickStart-AutoScale-From-25Percent-ARM-RDS-Redis_v13-12-3-ee_2021-07-24_102717_results.txt) | [1 YR Ec2 Compute Savings + 1 YR RDS & ElastiCache RIs](https://calculator.aws/#/estimate?id=330ee43c5b14662db5df6e52b34898d181a09e16) |
| [10K](../../administration/reference_architectures/10k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) | [10k Baseline](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/10k) | [10K Cloud Native Hybrid on EKS](#10k-cloud-native-hybrid-on-eks) | [10K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/10K/GL-CloudNative-10k-RDS-Graviton_v13-12-3-ee_2021-07-08_194647/GL-CloudNative-10k-RDS-Graviton_v13-12-3-ee_2021-07-08_194647_results.txt)<br /><br />[10K Elastic Auto Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/10K/GL-CloudNative-10k-AutoScaling-Test_v13-12-3-ee_2021-07-09_115139/GL-CloudNative-10k-AutoScaling-Test_v13-12-3-ee_2021-07-09_115139_results.txt) | [10K 1 YR Ec2 Compute Savings + 1 YR RDS & ElastiCache RIs](https://calculator.aws/#/estimate?id=5ac2e07a22e01c36ee76b5477c5a046cd1bea792) |
| [50K](../../administration/reference_architectures/50k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) | [50k Baseline](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Benchmarks/Latest/50k) | [50K Cloud Native Hybrid on EKS](#50k-cloud-native-hybrid-on-eks) | [50K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/50K/50k-Fixed-Scale-Test_v13-12-3-ee_2021-08-13_172819/50k-Fixed-Scale-Test_v13-12-3-ee_2021-08-13_172819_results.txt)<br /><br />[10K Elastic Auto Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/50K/50k-AutoScale-Test_v13-12-3-ee_2021-08-13_192633/50k-AutoScale-Test_v13-12-3-ee_2021-08-13_192633.txt) | [50K 1 YR Ec2 Compute Savings + 1 YR RDS & ElastiCache RIs](https://calculator.aws/#/estimate?id=b9c9d6ac1d4a7848011d2050cef3120931fb7c22) |

\*Cost calculations for actual implementations are a rough guideline with the following considerations:

- Actual choices about instance types should be based on GPT testing of your configuration.
- The first year of actual usage will reveal potential savings due to lower than expected usage, especially for ramping migrations where the full loading takes months, so be careful not to commit to savings plans too early or for too long.
- The cost estimates assume full scale of the Kubernetes cluster nodes 24 x 7 x 365. Savings due to 'idling scale-in' are not considered because they are highly dependent on the usage patterns of the specific implementation.
- Costs such as GitLab Runners, data egress and storage costs are not included as they are very dependent on the configuration of a specific implementation and on development behaviors (for example, frequency of committing or frequency of builds).
- These estimates will change over time as GitLab tests and optimizes compute choices.

## Available Infrastructure as Code for GitLab Cloud Native Hybrid

The [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md) is an effort made by GitLab to create a multi-cloud, multi-GitLab (Omnibus + Cloud Native Hybrid) toolkit to provision GitLab. GET is developed by GitLab developers and is open to community contributions. GET is where GitLab is investing its resources as the primary option for Infrastructure as Code, and is being actively used in production as a part of [GitLab Dedicated](../../subscriptions/gitlab_dedicated/index.md).

For more information about the project, see [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md).

The [AWS Quick Start for GitLab Cloud Native Hybrid on EKS](https://aws-quickstart.github.io/quickstart-eks-gitlab/) is developed by AWS, GitLab, and the community that contributes to AWS Quick Starts, whether directly to the GitLab Quick Start or to the underlying Quick Start dependencies GitLab inherits (for example, EKS Quick Start).

GET is recommended for most deployments. The AWS Quick Start can be used if the IaC language of choice is CloudFormation, integration with AWS services like Control Tower is desired, or preference for a UI-driven configuration experience or when any aspect in the below table is an overriding concern.

NOTE:
This automation is in **[Open Beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#open-beta)**. GitLab is working with AWS on resolving [the outstanding issues](https://github.com/aws-quickstart/quickstart-eks-gitlab/issues?q=is%3Aissue+is%3Aopen+%5BHL%5D) before it is fully released. You can subscribe to this issue to be notified of progress and release announcements: [AWS Quick Start for GitLab Cloud Native Hybrid on EKS Status: Beta](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues/11).<br><br>
The Beta version deploys Aurora PostgreSQL, but the release version will deploy Amazon RDS PostgreSQL due to [known issues](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues?label_name%5B%5D=AWS+Known+Issue) with Aurora. All performance testing results will also be redone after this change has been made.

|                                                              | [AWS Quick Start for GitLab Cloud Native Hybrid on EKS](https://aws-quickstart.github.io/quickstart-eks-gitlab/) | [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Overview and Vision                                          | [AWS Quick Start](https://aws.amazon.com/solutions/implementations/amazon-eks/)        | [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md) |
| Licensing                                                    | [Open Source (Apache 2.0)](https://github.com/aws-quickstart/quickstart-eks-gitlab/blob/main/LICENSE.txt) | [GitLab Enterprise Edition license](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/LICENSE) ([GitLab Premium tier](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md)) |
| GitLab Support                                               | [GitLab Beta Support](../../policy/alpha-beta-support.md#beta) | [GitLab GA Support](../../policy/alpha-beta-support.md#generally-available-ga) |
| GitLab Reference Architecture Compliant                      | Yes                                                          | Yes                                                          |
| GitLab Performance Tool (GPT) Tested                         | Yes                                                          | Yes                                                          |
| Amazon Well Architected Compliant                            | Yes<br />(via Quick Start program)                           | Critical portions <br />reviewed by AWS                      |
| Target Cloud Platforms                                       | AWS                                                          | AWS, Google, Azure                                           |
| IaC Languages                                                | CloudFormation (Quick Starts)                                | Terraform, Ansible                                           |
| Community Contributions and Participation (EcoSystem)        | <u>GitLab QSG</u>: Getting Started<br /><u>For QSG Dependencies (for example, EKS)</u>: Substantial | Getting Started                                              |
| Compatible with AWS Meta-Automation Services (via CloudFormation) | - [AWS Service Catalog](https://aws.amazon.com/servicecatalog/) (Direct Import)<br>- [ServiceNow via an AWS Service Catalog Connector](https://docs.aws.amazon.com/servicecatalog/latest/adminguide/integrations-servicenow.html#integrations-servicenow)<br>- [Jira Service Manager via an AWS Service Catalog Connector](https://docs.aws.amazon.com/servicecatalog/latest/adminguide/integrations-jiraservicedesk.html#integrations-jiraservicedesk)<br>- [AWS Control Tower](https://docs.aws.amazon.com/controltower/) ([Integration](https://aws.amazon.com/blogs/infrastructure-and-automation/deploy-aws-quick-start-to-multiple-accounts-using-aws-control-tower/))<br>- Quick Starts<br>- [AWS SaaS Factory](https://aws.amazon.com/partners/programs/saas-factory/) | No                                                           |
| Results in a Ready-to-Use instance                           | Yes                                                          | Manual Actions or <br />Supplemental IaC Required            |
| **<u>Configuration Features</u>**                            |                                                              |                                                              |
| Can deploy Omnibus GitLab (non-Kubernetes)                   | No                                                           | Yes                                                          |
| Can deploy Single Instance Omnibus GitLab (non-Kubernetes) | No                                                           | Yes                                                          |
| Complete Internal Encryption                                 | 85%, Targeting 100%                                          | Manual                                                       |
| AWS GovCloud Support                                         | Yes                                                          | TBD                                                          |
| No Code Form-Based Deployment User Experience Available    | Yes                                                          | No                                                          |
| Full IaC User Experience Available                         | Yes                                                          | Yes                                                          |

### Two and Three Zone High Availability

While GitLab Reference Architectures generally encourage three zone redundancy, AWS Quick Starts and AWS Well Architected consider two zone redundancy as AWS Well Architected. Individual implementations should weigh the costs of two and three zone configurations against their own high availability requirements for a final configuration.

Gitaly Cluster uses a consistency voting system to implement strong consistency between synchronized nodes. Regardless of the number of availability zones implemented, there will always need to be a minimum of three Gitaly and three Praefect nodes in the cluster to avoid voting stalemates cause by an even number of nodes.

### Streamlined Performance Testing of AWS Quick Start Prepared GitLab Instances

A set of performance testing instructions have been abbreviated for testing a GitLab instance prepared using the AWS Quick Start for GitLab Cloud Native Hybrid on EKS. They assume zero familiarity with GitLab Performance Tool. They can be accessed here: [Performance Testing an Instance Prepared using AWS Quick Start for GitLab Cloud Native Hybrid on EKS](https://gitlab.com/guided-explorations/aws/implementation-patterns/getting-started-gitlab-aws-quick-start/-/wikis/Easy-Performance-Testing-for-AWS-Quick-Start-for-GitLab-CNH).

### AWS GovCloud Support for AWS Quick Start for GitLab CNH on EKS

The AWS Quick Start for GitLab Cloud Native Hybrid on EKS has been tested with GovCloud and works with the following restrictions and understandings.

- GovCloud does not have public Route53 hosted zones, so you must set the following parameters:

  | CloudFormation Quick Start form field               | CloudFormation Parameter | Setting |
  | --------------------------------------------------- | ------------------------ | ------- |
  | **Create Route 53 hosted zone**                     | CreatedHostedZone        | No      |
  | **Request AWS Certificate Manager SSL certificate** | CreateSslCertificate     | No      |

- The Quick Start creates public load balancer IPs, so that you can easily configure your local hosts file to get to the GUI for GitLab when deploying tests. However, you may need to manually alter this if public load balancers are not part of your provisioning plan. We are planning to make non-public load balancers a configuration option issue link: [Short Term: Documentation and/or Automation for private GitLab instance with no internet Ingress](https://github.com/aws-quickstart/quickstart-eks-gitlab/issues/55)
- As of 2021-08-19, AWS GovCloud has Graviton instances for Amazon RDS PostgreSQL available, but does not for ElastiCache Redis.
- It is challenging to get the Quick Start template to load in GovCloud from the Standard Quick Start URL, so the generic ones are provided here:
  - [Launch for New VPC in us-gov-east-1](https://us-gov-east-1.console.amazonaws-us-gov.com/cloudformation/home?region=us-gov-east-1#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-for-EKS-New-VPC)
  - [Launch for New VPC in us-gov-west-1](https://us-gov-west-1.console.amazonaws-us-gov.com/cloudformation/home?region=us-gov-west-1#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-for-EKS-New-VPC)

## AWS PaaS qualified for all GitLab implementations

For both Omnibus GitLab or Cloud Native Hybrid implementations, the following GitLab Service roles can be performed by AWS Services (PaaS). Any PaaS solutions that require preconfigured sizing based on the scale of your instance will also be listed in the per-instance size Bill of Materials lists. Those PaaS that do not require specific sizing, are not repeated in the BOM lists (for example, AWS Certification Manager).

These services have been tested with GitLab.

Some services, such as log aggregation, outbound email are not specified by GitLab, but where provided are noted.

| GitLab Services                                              | AWS PaaS (Tested)              | Provided by AWS Cloud <br />Native Hybrid Quick Start        |
| ------------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------ |
| <u>Tested PaaS Mentioned in Reference Architectures</u>      |                                |                                                              |
| **PostgreSQL Database**                                      | Amazon RDS PostgreSQL          | Yes.                                                         |
| **Redis Caching**                                            | Redis ElastiCache              | Yes.                                                         |
| **Gitaly Cluster (Git Repository Storage)**<br />(Including Praefect and PostgreSQL) | ASG and Instances              | Yes - ASG and Instances<br />**Note: Gitaly cannot be put into a Kubernetes Cluster.** |
| **All GitLab storages besides Git Repository Storage**<br />(Includes Git-LFS which is S3 Compatible) | AWS S3                         | Yes                                                          |
|                                                              |                                |                                                              |
| <u>Tested PaaS for Supplemental Services</u>                 |                                |                                                              |
| **Front End Load Balancing**                                 | AWS ELB                        | Yes                                                          |
| **Internal Load Balancing**                                  | AWS ELB                        | Yes                                                          |
| **Outbound Email Services**                                  | AWS Simple Email Service (SES) | Yes                                                          |
| **Certificate Authority and Management**                     | AWS Certificate Manager (ACM)  | Yes                                                          |
| **DNS**                                                      | AWS Route53 (tested)           | Yes                                                          |
| **GitLab and Infrastructure Log Aggregation**                | AWS CloudWatch Logs            | Yes (ContainerInsights Agent for EKS)                        |
| **Infrastructure Performance Metrics**                       | AWS CloudWatch Metrics         | Yes                                                          |
|                                                              |                                |                                                              |
| <u>Supplemental Services and Configurations (Tested)</u>     |                                |                                                              |
| **Prometheus for GitLab**                                    | AWS EKS (Cloud Native Only)    | Yes                                                          |
| **Grafana for GitLab**                                       | AWS EKS (Cloud Native Only)    | Yes                                                          |
| **Administrative Access to GitLab Backend**                  | Bastion Host in VPC            | Yes - HA - Preconfigured for Cluster Management.             |
| **Encryption (In Transit / At Rest)**                        | AWS KMS                        | Yes                                                          |
| **Secrets Storage for Provisioning**                         | AWS Secrets Manager            | Yes                                                          |
| **Configuration Data for Provisioning**                      | AWS Parameter Store            | Yes                                                          |
| **AutoScaling Kubernetes**                                   | EKS AutoScaling Agent          | Yes                                                          |

## GitLab Cloud Native Hybrid on AWS

### 2K Cloud Native Hybrid on EKS

**2K Cloud Native Hybrid on EKS Bill of Materials (BOM)**

**GPT Test Results**

- TBD

 **Deploy Now**
 Deploy Now links leverage the AWS Quick Start automation and only pre-populate the number of instances and instance types for the Quick Start based on the Bill of Materials below. You must provide appropriate input for all other parameters by following the guidance in the [Quick Start documentation's Deployment steps](https://aws-quickstart.github.io/quickstart-eks-gitlab/#_deployment_steps) section.

- **Deploy Now: AWS Quick Start for 2 AZs**
- **Deploy Now: AWS Quick Start for 3 AZs**

NOTE:
On Demand pricing is used in this table for comparisons, but should not be used for budgeting nor purchasing AWS resources for a GitLab production instance. Do not use these tables to calculate actual monthly or yearly price estimates, instead use the AWS Calculator links in the "GitLab on AWS Compute" table above and customize it with your desired savings plan.

**BOM Total:** = Bill of Materials Total - this is what you use when building this configuration

**Ref Arch Raw Total:** = The totals if the configuration was built on regular VMs with no PaaS services. Configuring on pure VMs generally requires additional VMs for cluster management activities.

**Idle Configuration (Scaled-In)** = can be used to scale-in during time of low demand and/or for warm standby Geo instances. Requires configuration, testing and management of EKS autoscaling to meet your internal requirements.

| Service                                                      | Ref Arch Raw (Full Scaled) | AWS BOM                                                      | Example Full Scaled Cost<br />(On Demand, US East) |
| ------------------------------------------------------------ | -------------------------- | ------------------------------------------------------------ | -------------------------------------------------- |
| Webservice                                                   | 12 vCPU,16 GB              |                                                              |                                                    |
| Sidekiq                                                      | 2 vCPU, 8 GB               |                                                              |                                                    |
| Supporting services such as NGINX, Prometheus, etc           | 2 vCPU, 8 GB               |                                                              |                                                    |
| **GitLab Ref Arch Raw Total K8s Node Capacity**              | 16 vCPU, 32 GB             |                                                              |                                                    |
| One Node for Overhead and Miscellaneous (EKS Cluster AutoScaler, Grafana, Prometheus, etc) | + 8 vCPU, 16GB             |                                                              |                                                    |
| **Grand Total w/ Overheads**<br />Minimum hosts = 3          | 24 vCPU, 48 GB             | **c5.2xlarge** <br />(8vCPU/16GB) x 3 nodes<br />24 vCPU, 48 GB | $1.02/hr                                           |
| **Idle Configuration (Scaled-In)**                           | 16 vCPU, 32 GB             | **c5.2xlarge** x 2                                           | $0.68/hr                                           |

NOTE:
If EKS node autoscaling is employed, it is likely that your average loading will run lower than this, especially during non-working hours and weekends.

| Non-Kubernetes Compute                                       | Ref Arch Raw Total                                           | AWS BOM<br />(Directly Usable in AWS Quick Start)       | Example Cost<br />US East, 3 AZ | Example Cost<br />US East, 2 AZ |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------- | ------------------------------- |
| **Bastion Host (Quick Start)**                               | 1 HA instance in ASG                                         | **t2.micro** for prod, **m4.2xlarge** for performance testing |                                 |                                 |
| **PostgreSQL**<br />AWS Amazon RDS PostgreSQL Nodes Configuration (GPT tested) | 2vCPU, 7.5 GB<br />Tested with Graviton ARM                  | **db.r6g.large** x 3 nodes <br />(6vCPU, 48 GB)         | 3 nodes x $0.26 = $0.78/hr      | 3 nodes x $0.26 = $0.78/hr      |
| **Redis**                                                    | 1vCPU, 3.75GB<br />(across 12 nodes for Redis Cache, Redis Queues/Shared State, Sentinel Cache, Sentinel Queues/Shared State) | **cache.m6g.large** x 3 nodes<br />(6vCPU, 19GB)        | 3 nodes x $0.15 = $0.45/hr      | 2 nodes x $0.15 = $0.30/hr      |
| **<u>Gitaly Cluster</u>** [Details](gitlab_sre_for_aws.md#gitaly-sre-considerations) | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |                                                         |                                 |                                 |
| Gitaly Instances (in ASG)                                    | 12 vCPU, 45GB<br />(across 3 nodes)                          | **m5.xlarge** x 3 nodes<br />(48 vCPU, 180 GB)          | $0.192 x 3 = $0.58/hr           | $0.192 x 3 = $0.58/hr           |
|                                                              | The GitLab Reference architecture for 2K is not Highly Available and therefore has a single Gitaly no Praefect. AWS Quick Starts MUST be HA, so it implements Praefect from the 3K Ref Architecture to meet that requirement |                                                         |                                 |                                 |
| Praefect (Instances in ASG with load balancer)               | 6 vCPU, 10 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | **c5.large** x 3 nodes<br />(6 vCPU, 12 GB)             | $0.09 x 3 = $0.21/hr            | $0.09 x 3 = $0.21/hr            |
| Praefect PostgreSQL(1) (AWS RDS)                             | 6 vCPU, 5.4 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | Not applicable; reuses GitLab PostgreSQL                            | $0                              | $0                              |
| Internal Load Balancing Node                                 | 2 vCPU, 1.8 GB                                               | AWS ELB                                                 | $0.10/hr                        | $0.10/hr                        |

### 3K Cloud Native Hybrid on EKS

**3K Cloud Native Hybrid on EKS Bill of Materials (BOM)**

**GPT Test Results**

- [3K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/3K/3k-QuickStart-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_124216/3k-QuickStart-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_124216_results.txt)

- [3K AutoScale from 25% GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/3K/3k-QuickStart-AutoScale-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_194200/3k-QuickStart-AutoScale-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_194200_results.txt)

  Elastic Auto Scale GPT Test Results start with an idle scaled cluster and then start the standard GPT test to determine if the EKS Auto Scaler performs well enough to keep up with performance test demands. In general this is substantially harder ramping than the scaling required when the ramping is driven my normal production workloads.

**Deploy Now**

Deploy Now links leverage the AWS Quick Start automation and only pre-populate the number of instances and instance types for the Quick Start based on the Bill of Materials below. You must provide appropriate input for all other parameters by following the guidance in the [Quick Start documentation's Deployment steps](https://aws-quickstart.github.io/quickstart-eks-gitlab/#_deployment_steps) section.

- **[Deploy Now: AWS Quick Start for 2 AZs](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-EKS-3K-Users-2AZs&param_NumberOfAZs=2&param_NodeInstanceType=c5.2xlarge&param_NumberOfNodes=3&param_MaxNumberOfNodes=3&param_DBInstanceClass=db.r6g.xlarge&param_CacheNodes=2&param_CacheNodeType=cache.m6g.large&param_GitalyInstanceType=m5.large&param_NumberOfGitalyReplicas=3&param_PraefectInstanceType=c5.large&param_NumberOfPraefectReplicas=3)**
- **[Deploy Now: AWS Quick Start for 3 AZs](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-EKS-3K-Users-3AZs&param_NumberOfAZs=3&param_NodeInstanceType=c5.2xlarge&param_NumberOfNodes=3&param_MaxNumberOfNodes=3&param_DBInstanceClass=db.r6g.xlarge&param_CacheNodes=3&param_CacheNodeType=cache.m6g.large&param_GitalyInstanceType=m5.large&param_NumberOfGitalyReplicas=3&param_PraefectInstanceType=c5.large&param_NumberOfPraefectReplicas=3)**

NOTE:
On Demand pricing is used in this table for comparisons, but should not be used for budgeting nor purchasing AWS resources for a GitLab production instance. Do not use these tables to calculate actual monthly or yearly price estimates, instead use the AWS Calculator links in the "GitLab on AWS Compute" table above and customize it with your desired savings plan.

**BOM Total:** = Bill of Materials Total - this is what you use when building this configuration

**Ref Arch Raw Total:** = The totals if the configuration was built on regular VMs with no PaaS services. Configuring on pure VMs generally requires additional VMs for cluster management activities.

 **Idle Configuration (Scaled-In)** = can be used to scale-in during time of low demand and/or for warm standby Geo instances. Requires configuration, testing and management of EKS autoscaling to meet your internal requirements.

| Service                                                      | Ref Arch Raw (Full Scaled)                                   | AWS BOM                                                      | Example Full Scaled Cost<br />(On Demand, US East) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------------- |
| Webservice                                                   | [4 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/3k.yaml#L7) x ([5 vCPU & 6.25 GB](../../administration/reference_architectures/3k_users.md#webservice)) = <br />20 vCPU, 25 GB |                                                              |                                                    |
| Sidekiq                                                      | [8 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/3k.yaml#L24) x ([1 vCPU & 2 GB](../../administration/reference_architectures/3k_users.md#sidekiq)) = <br />8 vCPU, 16 GB |                                                              |                                                    |
| Supporting services such as NGINX, Prometheus, etc           | [2 allocations](../../administration/reference_architectures/3k_users.md#cluster-topology) x ([2 vCPU and 7.5 GB](../../administration/reference_architectures/3k_users.md#cluster-topology)) = <br />4 vCPU, 15 GB |                                                              |                                                    |
| **GitLab Ref Arch Raw Total K8s Node Capacity**              | 32 vCPU, 56 GB                                               |                                                              |                                                    |
| One Node for Overhead and Miscellaneous (EKS Cluster AutoScaler, Grafana, Prometheus, etc) | + 16 vCPU, 32GB                                              |                                                              |                                                    |
| **Grand Total w/ Overheads Full Scale**<br />Minimum hosts = 3 | 48 vCPU, 88 GB                                               | **c5.2xlarge** (8vCPU/16GB) x 5 nodes<br />40 vCPU, 80 GB<br />[Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/3K/3k-QuickStart-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_124216/3k-QuickStart-ARM-RDS-Cache_v13-12-3-ee_2021-07-23_124216_results.txt) | $1.70/hr                                           |
| **Possible Idle Configuration (Scaled-In 75% - round up)**<br />Pod autoscaling must be also adjusted to enable lower idling configuration. | 24 vCPU, 48 GB                                               | c5.2xlarge x 4                                               | $1.36/hr                                           |

Other combinations of node type and quantity can be used to meet the Grand Total. Due to the properties of pods, hosts that are overly small may have significant unused capacity.

NOTE:
If EKS node autoscaling is employed, it is likely that your average loading will run lower than this, especially during non-working hours and weekends.

| Non-Kubernetes Compute                                       | Ref Arch Raw Total                                           | AWS BOM<br />(Directly Usable in AWS Quick Start)       | Example Cost<br />US East, 3 AZ | Example Cost<br />US East, 2 AZ                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------- | ------------------------------------------------------------ |
| **Bastion Host (Quick Start)**                               | 1 HA instance in ASG                                         | **t2.micro** for prod, **m4.2xlarge** for performance testing |                                 |                                                              |
| **PostgreSQL**<br />Amazon RDS PostgreSQL Nodes Configuration (GPT tested) | 18vCPU, 36 GB <br />(across 9 nodes for PostgreSQL, PgBouncer, Consul)<br />Tested with Graviton ARM | **db.r6g.xlarge** x 3 nodes <br />(12vCPU, 96 GB)       | 3 nodes x $0.52 = $1.56/hr      | 3 nodes x $0.52 = $1.56/hr                                   |
| **Redis**                                                    | 6vCPU, 18GB<br />(across 6 nodes for Redis Cache, Sentinel)  | **cache.m6g.large** x 3 nodes<br />(6vCPU, 19GB)        | 3 nodes x $0.15 = $0.45/hr      | 2 nodes x $0.15 = $0.30/hr                                   |
| **<u>Gitaly Cluster</u>** [Details](gitlab_sre_for_aws.md#gitaly-sre-considerations) |                                                              |                                                         |                                 |                                                              |
| Gitaly Instances (in ASG)                                    | 12 vCPU, 45GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | **m5.large** x 3 nodes<br />(12 vCPU, 48 GB)            | $0.192 x 3 = $0.58/hr           | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect (Instances in ASG with load balancer)               | 6 vCPU, 5.4 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | **c5.large** x 3 nodes<br />(6 vCPU, 12 GB)             | $0.09 x 3 = $0.21/hr            | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect PostgreSQL(1) (Amazon RDS)                             | 6 vCPU, 5.4 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | Not applicable; reuses GitLab PostgreSQL                            | $0                              |                                                              |
| Internal Load Balancing Node                                 | 2 vCPU, 1.8 GB                                               | AWS ELB                                                 | $0.10/hr                        | $0.10/hr                                                     |

### 5K Cloud Native Hybrid on EKS

**5K Cloud Native Hybrid on EKS Bill of Materials (BOM)**

**GPT Test Results**

- [5K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/5K/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128_results.txt)

- [5K AutoScale from 25% GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/5K/5k-QuickStart-AutoScale-From-25Percent-ARM-RDS-Redis_v13-12-3-ee_2021-07-24_102717/5k-QuickStart-AutoScale-From-25Percent-ARM-RDS-Redis_v13-12-3-ee_2021-07-24_102717_results.txt)

  Elastic Auto Scale GPT Test Results start with an idle scaled cluster and then start the standard GPT test to determine if the EKS Auto Scaler performs well enough to keep up with performance test demands. In general this is substantially harder ramping than the scaling required when the ramping is driven my normal production workloads.

**Deploy Now**

Deploy Now links leverage the AWS Quick Start automation and only prepopulate the number of instances and instance types for the Quick Start based on the Bill of Materials below. You must provide appropriate input for all other parameters by following the guidance in the [Quick Start documentation's Deployment steps](https://aws-quickstart.github.io/quickstart-eks-gitlab/#_deployment_steps) section.

- **[Deploy Now: AWS Quick Start for 2 AZs](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-EKS-5K-Users-2AZs&param_NumberOfAZs=2&param_NodeInstanceType=c5.2xlarge&param_NumberOfNodes=5&param_MaxNumberOfNodes=5&param_DBInstanceClass=db.r6g.2xlarge&param_CacheNodes=2&param_CacheNodeType=cache.m6g.xlarge&param_GitalyInstanceType=m5.2xlarge&param_NumberOfGitalyReplicas=2&param_PraefectInstanceType=c5.large&param_NumberOfPraefectReplicas=2)**
- **[Deploy Now: AWS Quick Start for 3 AZs](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-EKS-5K-Users-3AZs&param_NumberOfAZs=3&param_NodeInstanceType=c5.2xlarge&param_NumberOfNodes=5&param_MaxNumberOfNodes=5&param_DBInstanceClass=db.r6g.2xlarge&param_CacheNodes=3&param_CacheNodeType=cache.m6g.xlarge&param_GitalyInstanceType=m5.2xlarge&param_NumberOfGitalyReplicas=3&param_PraefectInstanceType=c5.large&param_NumberOfPraefectReplicas=3)**

NOTE:
On Demand pricing is used in this table for comparisons, but should not be used for budgeting nor purchasing AWS resources for a GitLab production instance. Do not use these tables to calculate actual monthly or yearly price estimates, instead use the AWS Calculator links in the "GitLab on AWS Compute" table above and customize it with your desired savings plan.

**BOM Total:** = Bill of Materials Total - this is what you use when building this configuration

**Ref Arch Raw Total:** = The totals if the configuration was built on regular VMs with no PaaS services. Configuring on pure VMs generally requires additional VMs for cluster management activities.

**Idle Configuration (Scaled-In)** = can be used to scale-in during time of low demand and/or for warm standby Geo instances. Requires configuration, testing and management of EKS autoscaling to meet your internal requirements.

| Service                                                      | Ref Arch Raw (Full Scaled)                                   | AWS BOM                                                      | Example Full Scaled Cost<br />(On Demand, US East) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------------- |
| Webservice                                                   | [10 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/5k.yaml#L7) x ([5 vCPU & 6.25GB](../../administration/reference_architectures/5k_users.md#webservice)) = <br />50 vCPU, 62.5 GB |                                                              |                                                    |
| Sidekiq                                                      | [8 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/5k.yaml#L24) x ([1 vCPU & 2 GB](../../administration/reference_architectures/5k_users.md#sidekiq)) = <br />8 vCPU, 16 GB |                                                              |                                                    |
| Supporting services such as NGINX, Prometheus, etc           | [2 allocations](../../administration/reference_architectures/5k_users.md#cluster-topology) x ([2 vCPU and 7.5 GB](../../administration/reference_architectures/5k_users.md#cluster-topology)) = <br />4 vCPU, 15 GB |                                                              |                                                    |
| **GitLab Ref Arch Raw Total K8s Node Capacity**              | 62 vCPU, 96.5 GB                                             |                                                              |                                                    |
| One Node for Quick Start Overhead and Miscellaneous (EKS Cluster AutoScaler, Grafana, Prometheus, etc) | + 8 vCPU, 16GB                                               |                                                              |                                                    |
| **Grand Total w/ Overheads Full Scale**<br />Minimum hosts = 3 | 70 vCPU, 112.5 GB                                            | **c5.2xlarge** (8vCPU/16GB) x 9 nodes<br />72 vCPU, 144 GB<br />[Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/5K/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128/5k-QuickStart-ARM-RDS-Redis_v13-12-3-ee_2021-07-23_140128_results.txt) | $2.38/hr                                           |
| **Possible Idle Configuration (Scaled-In 75% - round up)**<br />Pod autoscaling must be also adjusted to enable lower idling configuration. | 24 vCPU, 48 GB                                               | c5.2xlarge x 7                                               | $1.85/hr                                           |

Other combinations of node type and quantity can be used to meet the Grand Total. Due to the CPU and memory requirements of pods, hosts that are overly small may have significant unused capacity.

NOTE:
If EKS node autoscaling is employed, it is likely that your average loading will run lower than this, especially during non-working hours and weekends.

| Non-Kubernetes Compute                                       | Ref Arch Raw Total                                           | AWS BOM<br />(Directly Usable in AWS Quick Start)       | Example Cost<br />US East, 3 AZ | Example Cost<br />US East, 2 AZ                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------- | ------------------------------------------------------------ |
| **Bastion Host (Quick Start)**                               | 1 HA instance in ASG                                         | **t2.micro** for prod, **m4.2xlarge** for performance testing |                                 |                                                              |
| **PostgreSQL**<br />Amazon RDS PostgreSQL Nodes Configuration (GPT tested) | 21vCPU, 51 GB <br />(across 9 nodes for PostgreSQL, PgBouncer, Consul)<br />Tested with Graviton ARM | **db.r6g.2xlarge** x 3 nodes <br />(24vCPU, 192 GB)     | 3 nodes x $1.04 = $3.12/hr      | 3 nodes x $1.04 = $3.12/hr                                   |
| **Redis**                                                    | 9vCPU, 27GB<br />(across 6 nodes for Redis, Sentinel)        | **cache.m6g.xlarge** x 3 nodes<br />(12vCPU, 39GB)      | 3 nodes x $0.30 = $0.90/hr      | 2 nodes x $0.30 = $0.60/hr                                   |
| **<u>Gitaly Cluster</u>** [Details](gitlab_sre_for_aws.md#gitaly-sre-considerations) |                                                              |                                                         |                                 |                                                              |
| Gitaly Instances (in ASG)                                    | 24 vCPU, 90GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | **m5.2xlarge** x 3 nodes<br />(24 vCPU, 96GB)           | $0.384 x 3 = $1.15/hr           | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect (Instances in ASG with load balancer)               | 6 vCPU, 5.4 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | **c5.large** x 3 nodes<br />(6 vCPU, 12 GB)             | $0.09 x 3 = $0.21/hr            | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect PostgreSQL(1) (Amazon RDS)                             | 6 vCPU, 5.4 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | Not applicable; reuses GitLab PostgreSQL                            | $0                              |                                                              |
| Internal Load Balancing Node                                 | 2 vCPU, 1.8 GB                                               | AWS ELB                                                 | $0.10/hr                        | $0.10/hr                                                     |

### 10K Cloud Native Hybrid on EKS

**10K Cloud Native Hybrid on EKS Bill of Materials (BOM)**

**GPT Test Results**

- [10K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/10K/GL-CloudNative-10k-RDS-Graviton_v13-12-3-ee_2021-07-08_194647/GL-CloudNative-10k-RDS-Graviton_v13-12-3-ee_2021-07-08_194647_results.txt)

- [10K Elastic Auto Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/10K/GL-CloudNative-10k-AutoScaling-Test_v13-12-3-ee_2021-07-09_115139/GL-CloudNative-10k-AutoScaling-Test_v13-12-3-ee_2021-07-09_115139_results.txt)

  Elastic Auto Scale GPT Test Results start with an idle scaled cluster and then start the standard GPT test to determine if the EKS Auto Scaler performs well enough to keep up with performance test demands. In general this is substantially harder ramping than the scaling required when the ramping is driven my normal production workloads.

**Deploy Now**

Deploy Now links leverage the AWS Quick Start automation and only prepopulate the number of instances and instance types for the Quick Start based on the Bill of Materials below. You must provide appropriate input for all other parameters by following the guidance in the [Quick Start documentation's Deployment steps](https://aws-quickstart.github.io/quickstart-eks-gitlab/#_deployment_steps) section.

- **[Deploy Now: AWS Quick Start for 3 AZs](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-EKS-10K-Users-3AZs&param_NumberOfAZs=3&param_NodeInstanceType=c5.4xlarge&param_NumberOfNodes=9&param_MaxNumberOfNodes=9&param_DBInstanceClass=db.r6g.2xlarge&param_CacheNodes=3&param_CacheNodeType=cache.m6g.2xlarge&param_GitalyInstanceType=m5.4xlarge&param_NumberOfGitalyReplicas=3&param_PraefectInstanceType=c5.large&param_NumberOfPraefectReplicas=3)**

NOTE:
On Demand pricing is used in this table for comparisons, but should not be used for budgeting nor purchasing AWS resources for a GitLab production instance. Do not use these tables to calculate actual monthly or yearly price estimates, instead use the AWS Calculator links in the "GitLab on AWS Compute" table above and customize it with your desired savings plan.

**BOM Total:** = Bill of Materials Total - this is what you use when building this configuration

**Ref Arch Raw Total:** = The totals if the configuration was built on regular VMs with no PaaS services. Configuring on pure VMs generally requires additional VMs for cluster management activities.

 **Idle Configuration (Scaled-In)** = can be used to scale-in during time of low demand and/or for warm standby Geo instances. Requires configuration, testing and management of EKS autoscaling to meet your internal requirements.

| Service                                                      | Ref Arch Raw (Full Scaled)                                   | AWS BOM<br />(Directly Usable in AWS Quick Start)            | Example Full Scaled Cost<br />(On Demand, US East) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------------- |
| Webservice                                                   | [20 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/10k.yaml#L7) x ([5 vCPU & 6.25 GB](../../administration/reference_architectures/10k_users.md#webservice)) = <br />100 vCPU, 125 GB |                                                              |                                                    |
| Sidekiq                                                      | [14 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/10k.yaml#L24) x ([1 vCPU & 2 GB](../../administration/reference_architectures/10k_users.md#sidekiq))<br />14 vCPU, 28 GB |                                                              |                                                    |
| Supporting services such as NGINX, Prometheus, etc           | [2 allocations](../../administration/reference_architectures/10k_users.md#cluster-topology) x ([2 vCPU and 7.5 GB](../../administration/reference_architectures/10k_users.md#cluster-topology))<br />4 vCPU, 15 GB |                                                              |                                                    |
| **GitLab Ref Arch Raw Total K8s Node Capacity**              | 128 vCPU, 158 GB                                             |                                                              |                                                    |
| One Node for Overhead and Miscellaneous (EKS Cluster AutoScaler, Grafana, Prometheus, etc) | + 16 vCPU, 32GB                                              |                                                              |                                                    |
| **Grand Total w/ Overheads Fully Scaled**<br />Minimum hosts = 3 | 142 vCPU, 190 GB                                             | **c5.4xlarge** (16vCPU/32GB) x 9 nodes<br />144 vCPU, 288GB<br /><br />[Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/10K/GL-CloudNative-10k-RDS-Graviton_v13-12-3-ee_2021-07-08_194647/GL-CloudNative-10k-RDS-Graviton_v13-12-3-ee_2021-07-08_194647_results.txt) | $6.12/hr                                           |
| **Possible Idle Configuration (Scaled-In 75% - round up)**<br />Pod autoscaling must be also adjusted to enable lower idling configuration. | 40 vCPU, 80 GB                                               | c5.4xlarge x 7<br /><br />[Elastic Auto Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/10K/GL-CloudNative-10k-AutoScaling-Test_v13-12-3-ee_2021-07-09_115139/GL-CloudNative-10k-AutoScaling-Test_v13-12-3-ee_2021-07-09_115139_results.txt) | $4.76/hr                                           |

Other combinations of node type and quantity can be used to meet the Grand Total. Due to the CPU and memory requirements of pods, hosts that are overly small may have significant unused capacity.

NOTE:
If EKS node autoscaling is employed, it is likely that your average loading will run lower than this, especially during non-working hours and weekends.

| Non-Kubernetes Compute | Ref Arch Raw Total | AWS BOM          | Example Cost<br />US East, 3 AZ | Example Cost<br />US East, 2 AZ |
| ------------------------------------------------------------ | ------------------------------ | ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Bastion Host (Quick Start)** | 1 HA instance in ASG | **t2.micro** for prod, **m4.2xlarge** for performance testing |  |  |
| **PostgreSQL**<br />Amazon RDS PostgreSQL Nodes Configuration (GPT tested) | 36vCPU, 102 GB <br />(across 9 nodes for PostgreSQL, PgBouncer, Consul) | **db.r6g.2xlarge** x 3 nodes <br />(24vCPU, 192 GB) | 3 nodes x $1.04 = $3.12/hr | 3 nodes x $1.04 = $3.12/hr |
| **Redis** | 30vCPU, 114GB<br />(across 12 nodes for Redis Cache, Redis Queues/Shared State, Sentinel Cache, Sentinel Queues/Shared State) | **cache.m5.2xlarge** x 3 nodes<br />(24vCPU, 78GB) | 3 nodes x $0.62 = $1.86/hr | 2 nodes x $0.62 = $1.24/hr |
| **<u>Gitaly Cluster</u>** [Details](gitlab_sre_for_aws.md#gitaly-sre-considerations) |  |  |  |  |
| Gitaly Instances (in ASG) | 48 vCPU, 180GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | **m5.4xlarge** x 3 nodes<br />(48 vCPU, 180 GB) | $0.77 x 3 = $2.31/hr | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect (Instances in ASG with load balancer) | 6 vCPU, 5.4 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | **c5.large** x 3 nodes<br />(6 vCPU, 12 GB) | $0.09 x 3 = $0.21/hr | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect PostgreSQL(1) (Amazon RDS) | 6 vCPU, 5.4 GB<br />([across 3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections)) | Not applicable; reuses GitLab PostgreSQL | $0 |  |
| Internal Load Balancing Node | 2 vCPU, 1.8 GB | AWS ELB | $0.10/hr | $0.10/hr |

### 50K Cloud Native Hybrid on EKS

**50K Cloud Native Hybrid on EKS Bill of Materials (BOM)**

**GPT Test Results**

- [50K Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/50K/50k-Fixed-Scale-Test_v13-12-3-ee_2021-08-13_172819/50k-Fixed-Scale-Test_v13-12-3-ee_2021-08-13_172819_results.txt)

- [50K Elastic Auto Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/50K/50k-AutoScale-Test_v13-12-3-ee_2021-08-13_192633/50k-AutoScale-Test_v13-12-3-ee_2021-08-13_192633.txt)

  Elastic Auto Scale GPT Test Results start with an idle scaled cluster and then start the standard GPT test to determine if the EKS Auto Scaler performs well enough to keep up with performance test demands. In general this is substantially harder ramping than the scaling required when the ramping is driven my normal production workloads.

**Deploy Now**

Deploy Now links leverage the AWS Quick Start automation and only prepopulate the number of instances and instance types for the Quick Start based on the Bill of Materials below. You must provide appropriate input for all other parameters by following the guidance in the [Quick Start documentation's Deployment steps](https://aws-quickstart.github.io/quickstart-eks-gitlab/#_deployment_steps) section.

- **[Deploy Now: AWS Quick Start for 3 AZs - 1/4 Scale EKS](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https://aws-quickstart.s3.us-east-1.amazonaws.com/quickstart-eks-gitlab/templates/gitlab-entry-new-vpc.template.yaml&stackName=Gitlab-EKS-50K-Users-3AZs&param_NumberOfAZs=3&param_NodeInstanceType=c5.4xlarge&param_NumberOfNodes=7&param_MaxNumberOfNodes=9&param_DBInstanceClass=db.r6g.8xlarge&param_CacheNodes=3&param_CacheNodeType=cache.m6g.2xlarge&param_GitalyInstanceType=m5.16xlarge&param_NumberOfGitalyReplicas=3&param_PraefectInstanceType=c5.xlarge&param_NumberOfPraefectReplicas=3)**

NOTE:
On Demand pricing is used in this table for comparisons, but should not be used for budgeting nor purchasing AWS resources for a GitLab production instance. Do not use these tables to calculate actual monthly or yearly price estimates, instead use the AWS Calculator links in the "GitLab on AWS Compute" table above and customize it with your desired savings plan.

**BOM Total:** = Bill of Materials Total - this is what you use when building this configuration

**Ref Arch Raw Total:** = The totals if the configuration was built on regular VMs with no PaaS services. Configuring on pure VMs generally requires additional VMs for cluster management activities.

 **Idle Configuration (Scaled-In)** = can be used to scale-in during time of low demand and/or for warm standby Geo instances. Requires configuration, testing and management of EKS autoscaling to meet your internal requirements.

| Service                                                      | Ref Arch Raw (Full Scaled)                                   | AWS BOM<br />(Directly Usable in AWS Quick Start)            | Example Full Scaled Cost<br />(On Demand, US East) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------------- |
| Webservice                                                   | [80 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/10k.yaml#L7) x ([5 vCPU & 6.25 GB](../../administration/reference_architectures/10k_users.md#webservice)) = <br />400 vCPU, 500 GB |                                                              |                                                    |
| Sidekiq                                                      | [14 pods](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/ref/10k.yaml#L24) x ([1 vCPU & 2 GB](../../administration/reference_architectures/10k_users.md#sidekiq))<br />14 vCPU, 28 GB |                                                              |                                                    |
| Supporting services such as NGINX, Prometheus, etc           | [2 allocations](../../administration/reference_architectures/10k_users.md#cluster-topology) x ([2 vCPU and 7.5 GB](../../administration/reference_architectures/10k_users.md#cluster-topology))<br />4 vCPU, 15 GB |                                                              |                                                    |
| **GitLab Ref Arch Raw Total K8s Node Capacity**              | 428 vCPU, 533 GB                                             |                                                              |                                                    |
| One Node for Overhead and Miscellaneous (EKS Cluster AutoScaler, Grafana, Prometheus, etc) | + 16 vCPU, 32GB                                              |                                                              |                                                    |
| **Grand Total w/ Overheads Fully Scaled**<br />Minimum hosts = 3 | 444 vCPU, 565 GB                                             | **c5.4xlarge** (16vCPU/32GB) x 28 nodes<br />448 vCPU, 896GB<br /><br />[Full Fixed Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/50K/50k-Fixed-Scale-Test_v13-12-3-ee_2021-08-13_172819/50k-Fixed-Scale-Test_v13-12-3-ee_2021-08-13_172819_results.txt) | $19.04/hr                                          |
| **Possible Idle Configuration (Scaled-In 75% - round up)**<br />Pod autoscaling must be also adjusted to enable lower idling configuration. | 40 vCPU, 80 GB                                               | c5.2xlarge x 10<br /><br />[Elastic Auto Scale GPT Test Results](https://gitlab.com/guided-explorations/aws/implementation-patterns/gitlab-cloud-native-hybrid-on-eks/-/blob/master/gitlab-alliances-testing/50K/50k-AutoScale-Test_v13-12-3-ee_2021-08-13_192633/50k-AutoScale-Test_v13-12-3-ee_2021-08-13_192633.txt) | $6.80/hr                                           |

Other combinations of node type and quantity can be used to meet the Grand Total. Due to the CPU and memory requirements of pods, hosts that are overly small may have significant unused capacity.

NOTE:
If EKS node autoscaling is employed, it is likely that your average loading will run lower than this, especially during non-working hours and weekends.

| Non-Kubernetes Compute                                       | Ref Arch Raw Total                                           | AWS BOM                                                   | Example Cost<br />US East, 3 AZ | Example Cost<br />US East, 2 AZ                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | --------------------------------------------------------- | ------------------------------- | ------------------------------------------------------------ |
| **Bastion Host (Quick Start)**                               | 1 HA instance in ASG                                         | **t2.micro** for prod, **m4.2xlarge** for performance testing   |                                 |                                                              |
| **PostgreSQL**<br />Amazon RDS PostgreSQL Nodes Configuration (GPT tested) | 96vCPU, 360 GB <br />(across 3 nodes)                        | **db.r6g.8xlarge** x 3 nodes <br />(96vCPU, 768 GB total) | 3 nodes x $4.15 = $12.45/hr     | 3 nodes x $4.15 = $12.45/hr                                  |
| **Redis**                                                    | 30vCPU, 114GB<br />(across 12 nodes for Redis Cache, Redis Queues/Shared State, Sentinel Cache, Sentinel Queues/Shared State) | **cache.m6g.2xlarge** x 3 nodes<br />(24vCPU, 78GB total) | 3 nodes x $0.60 = $1.80/hr      | 2 nodes x $0.60 = $1.20/hr                                   |
| **<u>Gitaly Cluster</u>** [Details](gitlab_sre_for_aws.md#gitaly-sre-considerations) |                                                              |                                                           |                                 |                                                              |
| Gitaly Instances (in ASG)                                    | 64 vCPU, 240GB x [3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) | **m5.16xlarge** x 3 nodes<br />(64 vCPU, 256 GB each)     | $3.07 x 3 = $9.21/hr            | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect (Instances in ASG with load balancer)               | 4 vCPU, 3.6 GB x [3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) | **c5.xlarge** x 3 nodes<br />(4 vCPU, 8 GB each)          | $0.17 x 3 = $0.51/hr            | [Gitaly & Praefect Must Have an Uneven Node Count for HA](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) |
| Praefect PostgreSQL(1) (AWS RDS)                             | 2 vCPU, 1.8 GB x [3 nodes](gitlab_sre_for_aws.md#gitaly-and-praefect-elections) | Not applicable; reuses GitLab PostgreSQL                              | $0                              |                                                              |
| Internal Load Balancing Node                                 | 2 vCPU, 1.8 GB                                               | AWS ELB                                                   | $0.10/hr                        | $0.10/hr                                                     |

## Helpful Resources

- [Architecting Kubernetes clusters — choosing a worker node size](https://learnk8s.io/kubernetes-node-size)

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.
