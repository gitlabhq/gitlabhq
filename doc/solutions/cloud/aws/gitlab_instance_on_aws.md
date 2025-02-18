---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Provision GitLab Instances on AWS
---

## Available Infrastructure as Code for GitLab Instance Installation on AWS

The [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md) is a set of opinionated Terraform and Ansible scripts. These scripts help with the deployment of Linux package or Cloud Native Hybrid environments on selected cloud providers and are used by GitLab developers for [GitLab Dedicated](../../../subscriptions/gitlab_dedicated/_index.md) (for example).

You can use the GitLab Environment Toolkit to deploy a Cloud Native Hybrid environment on AWS. However, it's not required and may not support every valid permutation. That said, the scripts are presented as-is and you can adapt them accordingly.

### Two and Three Zone High Availability

While GitLab Reference Architectures generally encourage three zone redundancy, the AWS Well Architected framework consider two zone redundancy as AWS Well Architected. Individual implementations should weigh the costs of two and three zone configurations against their own high availability requirements for a final configuration.

Gitaly Cluster uses a consistency voting system to implement strong consistency between synchronized nodes. Regardless of the number of availability zones implemented, there will always need to be a minimum of three Gitaly and three Praefect nodes in the cluster to avoid voting stalemates cause by an even number of nodes.

## AWS PaaS qualified for all GitLab implementations

For both implementations that used the Linux package or Cloud Native Hybrid implementations, the following GitLab Service roles can be performed by AWS Services (PaaS). Any PaaS solutions that require preconfigured sizing based on the scale of your instance will also be listed in the per-instance size Bill of Materials lists. Those PaaS that do not require specific sizing, are not repeated in the BOM lists (for example, AWS Certification Manager).

These services have been tested with GitLab.

Some services, such as log aggregation, outbound email are not specified by GitLab, but where provided are noted.

| GitLab Services                                              | AWS PaaS (Tested)              |
| ------------------------------------------------------------ | ------------------------------ |
| <u>Tested PaaS Mentioned in Reference Architectures</u>      |                                |
| **PostgreSQL Database**                                      | Amazon RDS PostgreSQL          |
| **Redis Caching**                                            | Redis ElastiCache              |
| **Gitaly Cluster (Git Repository Storage)**<br />(Including Praefect and PostgreSQL) | ASG and Instances              |
| **All GitLab storages besides Git Repository Storage**<br />(Includes Git-LFS which is S3 Compatible) | AWS S3                         |
|                                                              |                                |
| <u>Tested PaaS for Supplemental Services</u>                 |                                |
| **Front End Load Balancing**                                 | AWS ELB                        |
| **Internal Load Balancing**                                  | AWS ELB                        |
| **Outbound Email Services**                                  | AWS Simple Email Service (SES) |
| **Certificate Authority and Management**                     | AWS Certificate Manager (ACM)  |
| **DNS**                                                      | AWS Route53 (tested)           |
| **GitLab and Infrastructure Log Aggregation**                | AWS CloudWatch Logs            |
| **Infrastructure Performance Metrics**                       | AWS CloudWatch Metrics         |
|                                                              |                                |
| <u>Supplemental Services and Configurations</u>              |                                |
| **Prometheus for GitLab**                                    | AWS EKS (Cloud Native Only)    |
| **Grafana for GitLab**                                       | AWS EKS (Cloud Native Only)    |
| **Encryption (In Transit / At Rest)**                        | AWS KMS                        |
| **Secrets Storage for Provisioning**                         | AWS Secrets Manager            |
| **Configuration Data for Provisioning**                      | AWS Parameter Store            |
| **AutoScaling Kubernetes**                                   | EKS AutoScaling Agent          |
