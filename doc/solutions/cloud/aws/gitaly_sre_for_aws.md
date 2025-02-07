---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: Doing SRE for Gitaly instances on AWS.
title: SRE Considerations for Gitaly on AWS
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

## Gitaly SRE considerations

Gitaly is an embedded service for Git Repository Storage. Gitaly and Gitaly Cluster have been engineered by GitLab to overcome fundamental challenges with horizontal scaling of the open source Git binaries that must be used on the service side of GitLab. Here is in-depth technical reading on the topic:

### Why Gitaly was built

If you would like to understand the underlying rationale on why GitLab had to invest in creating Gitaly, read the following minimal list of topics:

- [Git characteristics that make horizontal scaling difficult](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-characteristics-that-make-horizontal-scaling-difficult)
- [Git architectural characteristics and assumptions](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-architectural-characteristics-and-assumptions)
- [Affects on horizontal compute architecture](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#affects-on-horizontal-compute-architecture)
- [Evidence to back building a new horizontal layer to scale Git](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#evidence-to-back-building-a-new-horizontal-layer-to-scale-git)

### Gitaly and Praefect elections

As part of Gitaly cluster consistency, Praefect nodes must occasionally vote on what data copy is the most accurate. This requires an uneven number of Praefect nodes to avoid stalemates. This means that for HA, Gitaly and Praefect require a minimum of three nodes.

### Gitaly performance monitoring

Complete performance metrics should be collected for Gitaly instances for identification of bottlenecks, as they could have to do with disk IO, network IO, or memory.

### Gitaly performance guidelines

Gitaly functions as the primary Git Repository Storage in GitLab. However, it's not a streaming file server. It also does a lot of demanding computing work, such as preparing and caching Git packfiles which informs some of the performance recommendations below.

NOTE:
All recommendations are for production configurations, including performance testing. For test configurations, like training or functional testing, you can use less expensive options. However, you should adjust or rebuild if performance is an issue.

#### Overall recommendations

- Production-grade Gitaly must be implemented on instance compute due to all of the above and below characteristics.
- Never use [burstable instance types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html) (such as `t2`, `t3`, `t4g`) for Gitaly.
- Always use at least the [AWS Nitro generation of instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#ec2-nitro-instances) to ensure many of the below concerns are automatically handled.
- Use Amazon Linux 2 to ensure that all [AWS oriented hardware and OS optimizations](https://aws.amazon.com/amazon-linux-2/faqs/) are maximized without additional configuration or SRE management.

#### CPU and memory recommendations

- The general GitLab Gitaly node recommendations for CPU and Memory assume relatively even loading across repositories. GitLab Performance Tool (GPT) testing of any non-characteristic repositories and/or SRE monitoring of Gitaly metrics may inform when to choose memory and/or CPU higher than general recommendations.

**To accommodate:**

- Git packfile operations are memory and CPU intensive.
- If repository commit traffic is dense, large, or very frequent, then more CPU and Memory are required to handle the load. Patterns such as storing binaries and/or busy or large monorepos are examples that can cause high loading.

#### Disk I/O recommendations

- Use only SSD storage and the [class of Elastic Block Store (EBS) storage](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) that suites your durability and speed requirements.
- When not using provisioned EBS IO, EBS volume size determines the I/O level, so provisioning volumes that are much larger than needed can be the least expensive way to improve EBS IO.
- If Gitaly performance monitoring shows signs of disk stress then one of the provisioned IOPS levels can be chosen. EBS IOPS levels also have enhanced durability which may be appealing for some implementations aside from performance considerations.

**To accommodate:**

- Gitaly storage is expected to be local (not NFS of any type including EFS).
- Gitaly servers also need disk space for building and caching Git packfiles. This is above and beyond the permanent storage of your Git Repositories.
- Git packfiles are cached in Gitaly. Creation of packfiles in temporary disk benefits from fast disk, and disk caching of packfiles benefits from ample disk space.

#### Network I/O recommendations

- Use only instance types [from the list of ones that support Elastic Network Adapter (ENA) advanced networking](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#instance-type-summary-table) to ensure that cluster replication latency is not due to instance level network I/O bottlenecks.
- Choose instances with sizes with more than 10 Gbps - but only if needed and only when having proven a node level network bottleneck with monitoring and/or stress testing.

**To accommodate:**

- Gitaly nodes do the main work of streaming repositories for push and pull operations (to add development endpoints, and to CI/CD).
- Gitaly servers need reasonable low latency between cluster nodes and with Praefect services in order for the cluster to maintain operational and data integrity.
- Gitaly nodes should be selected with network bottleneck avoidance as a primary consideration.
- Gitaly nodes should be monitored for network saturation.
- Not all networking issues can be solved through optimizing the node level networking:
  - Gitaly cluster node replication depends on all networking between nodes.
  - Gitaly networking performance to pull and push endpoints depends on all networking in between.

### AWS Gitaly backup

Due to the nature of how Praefect tracks the replication metadata of Gitaly disk information, the best backup method is [the official backup and restore Rake tasks](../../../administration/backup_restore/_index.md).

### AWS Gitaly recovery

Gitaly Cluster does not support snapshot backups as these can cause issues where the Praefect database becomes out of syn with the disk storage. Due to the nature of how Praefect rebuilds the replication metadata of Gitaly disk information during a restore, the best recovery method is [the official backup and restore Rake tasks](../../../administration/backup_restore/_index.md).

### Gitaly long term management

Gitaly node disk sizes must be monitored and increased to accommodate Git repository growth and Gitaly temporary and caching storage needs. The storage configuration on all nodes should be kept identical.
