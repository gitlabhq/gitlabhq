---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Reference architecture: up to 1,000 users **(FREE SELF)**

This page describes GitLab reference architecture for up to 1,000 users. For a
full list of reference architectures, see
[Available reference architectures](index.md#available-reference-architectures).

If you need to serve up to 1,000 users and you don't have strict availability
requirements, a single-node solution with
[frequent backups](index.md#automated-backups) is appropriate for
many organizations .

> - **Supported users (approximate):** 1,000
> - **High Availability:** No. For a highly-available environment, you can
>   follow a modified [3K reference architecture](3k_users.md#supported-modifications-for-lower-user-counts-ha).
> - **Test requests per second (RPS) rates:** API: 20 RPS, Web: 2 RPS, Git (Pull): 2 RPS, Git (Push): 1 RPS

| Users        | Configuration           | GCP            | AWS          | Azure    |
|--------------|-------------------------|----------------|--------------|----------|
| Up to 500    | 4 vCPU, 3.6 GB memory   | `n1-highcpu-4` | `c5.xlarge`  | `F4s v2` |
| Up to 1,000  | 8 vCPU, 7.2 GB memory   | `n1-highcpu-8` | `c5.2xlarge` | `F8s v2` |

The Google Cloud Platform (GCP) architectures were built and tested using the
[Intel Xeon E5 v3 (Haswell)](https://cloud.google.com/compute/docs/cpu-platforms)
CPU platform. On different hardware you may find that adjustments, either lower
or higher, are required for your CPU or node counts. For more information, see
our [Sysbench](https://github.com/akopytov/sysbench)-based
[CPU benchmarks](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Reference-Architectures/GCP-CPU-Benchmarks).

In addition to the stated configurations, we recommend having at least 2 GB of
swap on your server, even if you currently have enough available memory. Having
swap helps to reduce the chance of errors occurring if your available memory
changes. We also recommend configuring the kernel's swappiness setting to a
lower value (such as `10`) to make the most of your memory, while still having
the swap available when needed.

## Setup instructions

To install GitLab for this default reference architecture, use the standard
[installation instructions](../../install/index.md).

You can also optionally configure GitLab to use an [external PostgreSQL service](../postgresql/external.md)
or an [external object storage service](../object_storage.md) for added
performance and reliability at an increased complexity cost.

## Configure Advanced Search **(PREMIUM SELF)**

You can leverage Elasticsearch and [enable Advanced Search](../../integration/elasticsearch.md)
for faster, more advanced code search across your entire GitLab instance.

Elasticsearch cluster design and requirements are dependent on your specific
data. For recommended best practices about how to set up your Elasticsearch
cluster alongside your instance, read how to
[choose the optimal cluster configuration](../../integration/elasticsearch.md#guidance-on-choosing-optimal-cluster-configuration).
