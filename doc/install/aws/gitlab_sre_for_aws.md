---
stage: Enablement
group: Alliances
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
description: Doing SRE for GitLab instances and runners on AWS.
type: index
---

# GitLab Site Reliability Engineering for AWS **(FREE SELF)**

## Known issues list

Known issues are gathered from within GitLab and from customer reported issues. Customers successfully implement GitLab with a variety of "as a Service" components that GitLab has not specifically been designed for, nor has ongoing testing for. While GitLab does take partner technologies very seriously, the highlighting of known issues here is a convenience for implementers and it does not imply that GitLab has targeted compatibility with, nor carries any type of guarantee of running on the partner technology where the issues occur. Please consult individual issues to understand GitLabs stance and plans on any given known issue.

See the [GitLab AWS known issues list](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues?label_name%5B%5D=AWS+Known+Issue) for a complete list.

## Gitaly SRE considerations

Gitaly and Gitaly Cluster have been engineered by GitLab to overcome fundamental challenges with horizontal scaling of the open source Git binaries. Here is indepth technical reading on the topic:

### Why Gitaly was built

Below are some links to better understand why Gitaly was built:

- [Git characteristics that make horizontal scaling difficult](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-characteristics-that-make-horizontal-scaling-difficult)
- [Git architectural characteristics and assumptions](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-architectural-characteristics-and-assumptions)
- [Affects on horizontal compute architecture](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#affects-on-horizontal-compute-architecture)
- [Evidence to back building a new horizontal layer to scale Git](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#evidence-to-back-building-a-new-horizontal-layer-to-scale-git)

### Gitaly and Praefect elections

As part of Gitaly cluster consistency, Praefect nodes will occasionally need to vote on what data copy is the most accurate. This requires an uneven number of Praefect nodes to avoid stalemates. This means that for HA, Gitaly and Praefect require a minimum of three nodes.

### Gitaly performance monitoring

Complete performance metrics should be collected for Gitaly instances for identification of bottlenecks, as they could have to do with disk IO, network IO or memory.

Gitaly must be implemented on instance compute.

### Gitaly EBS volume sizing guidelines

Gitaly storage is expected to be local (not NFS of any type including EFS).
Gitaly servers also need disk space for building and caching Git pack files.

Background:

- When not using provisioned EBS IO, EBS volume size determines the IO level, so provisioning volumes that are much larger than needed can be the least expensive way to improve EBS IO.
- Only use nitro instance types due to higher IO and EBS optimization.
- Use Amazon Linux 2 to ensure the best disk and memory optimizations (for example, ENA network adapters and drivers).
- If GitLab backup scripts are used, they need a temporary space location large enough to hold 2 times the current size of the Git File system. If that will be done on Gitaly servers, separate volumes should be used.

### Gitaly HA in EKS quick start

The [AWS GitLab Cloud Native Hybrid on EKS Quick Start](gitlab_hybrid_on_aws.md#available-infrastructure-as-code-for-gitlab-cloud-native-hybrid) for GitLab Cloud Native implements Gitaly as a multi-zone, self-healing infrastructure. It has specific code for reestablishing a Gitaly node when one fails, including AZ failure.

### Gitaly long term management

Gitaly node disk sizes will need to be monitored and increased to accommodate Git repository growth and Gitaly temporary and caching storage needs. The storage configuration on all nodes should be kept identical.
