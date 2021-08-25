---
type: reference, concepts
stage: Enablement
group: Alliances
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Gitaly SRE Considerations

Gitaly and Gitaly Cluster have been engineered by GitLab to overcome fundamental challenges with horizontal scaling of the open source Git binaries. Here is indepth technical reading on the topic:

## Why Gitaly was built

Below are some links to better understand why Gitaly was built:

- [Git characteristics that make horizontal scaling difficult](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-characteristics-that-make-horizontal-scaling-difficult)
- [Git architectural characteristics and assumptions](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#git-architectural-characteristics-and-assumptions)
- [Affects on horizontal compute architecture](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#affects-on-horizontal-compute-architecture)
- [Evidence to back building a new horizontal layer to scale Git](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/DESIGN.md#evidence-to-back-building-a-new-horizontal-layer-to-scale-git)

## Gitaly and Praefect elections

As part of Gitaly cluster consistency, Praefect nodes will occasionally need to vote on what data copy is the most accurate. This requires an uneven number of Praefect nodes to avoid stalemates. This means that for HA, Gitaly and Praefect require a minimum of three nodes.

## Gitaly performance monitoring

Complete performance metrics should be collected for Gitaly instances for identification of bottlenecks, as they could have to do with disk IO, network IO or memory.

Gitaly must be implemented on instance compute.

## Gitaly EBS volume sizing guidelines

Gitaly storage is expected to be local (not NFS of any type including EFS).
Gitaly servers also need disk space for building and caching Git pack files.

Background:

- When not using provisioned EBS IO, EBS volume size determines the IO level, so provisioning volumes that are much larger than needed can be the least expensive way to improve EBS IO.
- Only use nitro instance types due to higher IO and EBS optimization.
- Use Amazon Linux 2 to ensure the best disk and memory optimizations (for example, ENA network adapters and drivers).
- If GitLab backup scripts are used, they need a temporary space location large enough to hold 2 times the current size of the Git File system. If that will be done on Gitaly servers, separate volumes should be used. 

## Gitaly HA in EKS quick start

The AWS EKS quick start for GitLab Cloud Native implements Gitaly as a multi-zone, self-healing infrastructure. It has specific code for reestablishing a Gitaly node when one fails, including AZ failure.

## Gitaly long term management

Gitaly node disk sizes will need to be monitored and increased to accommodate Git repository growth and Gitaly temporary and caching storage needs. The storage configuration on all nodes should be kept identical.
