---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation on large repositories."
---

# Managing large repositories **(FREE SELF)**

GitLab, like any Git based system, is subject to similar performance restraints when it comes to large
repositories that size into the gigabytes.

In the following sections, we detail several best practices for improving performance with these large repositories on GitLab.

## Large File System (LFS)

It's *strongly* recommended in any Git system that binary or blob files (for example, packages, audio, video, or graphics) are stored as Large File Storage (LFS) objects. With LFS, the objects are stored externally, such as in Object Storage, which reduces the number and size of objects in the repository. Storing objects in external Object Storage can improve performance.

To analyze if a repository has large objects, you can use a tool like [`git-sizer`](https://github.com/github/git-sizer) for detailed analysis. This tool shows details about what makes up the repository, and highlights any areas of concern. If any large objects are found, you can then remove them with a tool such as [`git filter-repo`](reducing_the_repo_size_using_git.md).

For more information, refer to the [Git LFS documentation](../../../topics/git/lfs/index.md).

## Gitaly Pack Objects Cache

Gitaly, the service that provides storage for Git repositories, can be configured to cache a short rolling window of Git fetch responses. This is recommended for large repositories as it can notably reduce server load when your server receives lots of fetch traffic.

Refer to the [Gitaly Pack Objects Cache for more information](../../../administration/gitaly/configure_gitaly.md#pack-objects-cache).

## Reference Architectures

Large repositories tend to be found in larger organisations with many users. The GitLab Quality and Support teams provide several [Reference Architectures](../../../administration/reference_architectures/index.md) that are the recommended way to deploy GitLab at scale.

In these types of setups it's recommended that the GitLab environment used matches a Reference Architecture to improve performance.

## Gitaly Cluster

Gitaly Cluster can notably improve large repository performance as it holds multiple replicas of the repository across several nodes. As a result, Gitaly Cluster can load balance read requests against those repositories and is also fault-tolerant.

It's recommended for large repositories, however, Gitaly Cluster is a large solution with additional complexity of setup, and management. Refer to the [Gitaly Cluster documentation for more information](../../../administration/gitaly/index.md), specifically the [Before deploying Gitaly Cluster](../../../administration/gitaly/index.md#before-deploying-gitaly-cluster) section.

## Keep GitLab up to date

Performance improvements and fixes are added continuously in GitLab. As such, it's recommended you keep GitLab updated to the latest version where possible to benefit from these.

## Reduce concurrent clones in CI/CD

Large repositories tend to be monorepos. This in turn typically means that these repositories get a lot of traffic not only from users, but from CI/CD.

CI/CD loads tend to be concurrent as pipelines are scheduled during set times. As a result, the Git requests against the repositories can spike notably during these times and lead to reduced performance for both CI and users alike.

When designing CI/CD pipelines, it's advisable to reduce their concurrency by staggering them to run at different times, for example, a set running at one time, and another set running several minutes later.

There's several other actions that can be explored to improve CI/CD performance with large repositories. Refer to the [Runner documentation for more information](../../../ci/large_repositories/index.md).
