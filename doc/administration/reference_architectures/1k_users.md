---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Reference architecture: Up to 20 RPS or 1,000 users'
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This reference architecture targets a peak load of 20 requests per second (RPS). Based on real data, this load typically corresponds to up to 1,000 users, which includes both manual and automated interactions.

For a full list of reference architectures, see
[available reference architectures](_index.md#available-reference-architectures).

> - **Target Load:** API: 20 RPS, Web: 2 RPS, Git (Pull): 2 RPS, Git (Push): 1 RPS
> - **High Availability:** No. For a high availability environment,
>   follow a modified [3K reference architecture](3k_users.md#supported-modifications-for-lower-user-counts-ha).
> - **Cost calculator template:** For more information, see [cost calculator templates](_index.md#cost-calculator-templates).
> - **Cloud Native Hybrid:** No. For a cloud native hybrid environment, you
>   can follow a [modified hybrid reference architecture](#cloud-native-hybrid-reference-architecture-with-helm-charts).
> - **Unsure which Reference Architecture to use?** For more information, see [deciding which architecture to start with](_index.md#deciding-which-architecture-to-start-with).

| Users        | Configuration        | GCP example<sup>1</sup> | AWS example<sup>1</sup> | Azure example<sup>1</sup> |
|--------------|----------------------|----------------|--------------|----------|
| Up to 1,000 or 20 RPS | 8 vCPU, 16 GB memory | `n1-standard-8`<sup>2</sup> | `c5.2xlarge` | `F8s v2` |

**Footnotes:**

<!-- Disable ordered list rule https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix -->
<!-- markdownlint-disable MD029 -->
1. Machine type examples are given for illustration purposes. These types are used in [validation and testing](_index.md#validation-and-test-results) but are not intended as prescriptive defaults. Switching to other machine types that meet the requirements as listed is supported, including ARM variants if available. See [Supported machine types](_index.md#supported-machine-types) for more information.
2. For GCP, the closest and equivalent standard machine type has been selected that matches the recommended requirement of 8 vCPU and 16 GB of RAM. A [custom machine type](https://cloud.google.com/compute/docs/instances/creating-instance-with-custom-machine-type) can also be used if desired.
<!-- markdownlint-enable MD029 -->

The following diagram shows that while GitLab can be installed on a single server, it is internally composed of multiple services. When an instance scales, these services are separated and independently scaled according to their specific demands.

In some cases, you can leverage PaaS for some services. For example, you can use Cloud Object Storage for some file systems. For the sake of redundancy, some services become clusters of nodes and store the same data.

In a horizontally scaled GitLab configuration, various ancillary services are required to coordinate clusters or discover resources. For example, PgBouncer for PostgreSQL connection management, or Consul for Prometheus end point discovery.

```plantuml
@startuml 1k
card "**Prometheus**" as monitor #7FFFD4
package "GitLab Single Server" as gitlab-single-server {
together {
  card "**GitLab Rails**" as gitlab #32CD32
  card "**Gitaly**" as gitaly #FF8C00
  card "**PostgreSQL**" as postgres #4EA7FF
  card "**Redis**" as redis #FF6347
  card "**Sidekiq**" as sidekiq #ff8dd1
}
card "Local Storage" as local_storage #white
}

gitlab -[#32CD32]--> gitaly
gitlab -[#32CD32]--> postgres
gitlab -[#32CD32]--> redis
gitlab -[#32CD32]--> sidekiq
gitaly -[#32CD32]--> local_storage
postgres -[#32CD32]--> local_storage
sidekiq -[#32CD32]--> local_storage
gitlab -[#32CD32]--> local_storage

monitor .[#7FFFD4]u-> gitlab
monitor .[#7FFFD4]u-> sidekiq
monitor .[#7FFFD4]-> postgres
monitor .[#7FFFD4]-> gitaly
monitor .[#7FFFD4,norank]--> redis

@enduml
```

## Requirements

Before proceeding, review the [requirements](_index.md#requirements) for the reference architectures.

{{< alert type="warning" >}}

**The node's specifications are based on high percentiles of both usage patterns and repository sizes in good health.**
**However, if you have [large monorepos](_index.md#large-monorepos) (larger than several gigabytes) or [additional workloads](_index.md#additional-workloads), they might *significantly* impact the performance of the environment.**
If this applies to you, [further adjustments might be required](_index.md#scaling-an-environment). See the linked documentation and contact us if required for further guidance.

{{< /alert >}}

## Testing methodology

The 20 RPS / 1k user reference architecture is designed to accommodate most common workflows. The [GitLab Delivery: Framework](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/framework/) team regularly conducts smoke and performance testing against the following endpoint throughput targets:

| Endpoint type | Target throughput |
| ------------- | ----------------- |
| API           | 20 RPS            |
| Web           | 2 RPS             |
| Git (Pull)    | 2 RPS             |
| Git (Push)    | 1 RPS             |

These targets are based on actual customer data reflecting total environmental loads for the specified user count, including CI pipelines and other workloads.

For more information about our testing methodology, see the [validation and test results](_index.md#validation-and-test-results) section.

### Performance considerations

You may need additional adjustments if your environment has:

- Consistently higher throughput than the listed targets
- [Large monorepos](_index.md#large-monorepos)
- Significant [additional workloads](_index.md#additional-workloads)

In these cases, refer to [scaling an environment](_index.md#scaling-an-environment) for more information. If you believe these considerations may apply to you, contact us for additional guidance as required.

## Setup instructions

To install GitLab for this default reference architecture, use the standard
[installation instructions](../../install/_index.md).

You can also optionally configure GitLab to use an [external PostgreSQL service](../postgresql/external.md)
or [external object storage service](../object_storage.md). It improves performance and reliability, but at an increased complexity cost.

## Configure advanced search

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can leverage Elasticsearch and [enable advanced search](../../integration/advanced_search/elasticsearch.md)
for faster, more advanced code search across your entire GitLab instance.

Elasticsearch cluster design and requirements depends on your
data. For recommended best practices about how to set up your Elasticsearch
cluster alongside your instance, see
[choose the optimal cluster configuration](../../integration/advanced_search/elasticsearch.md#guidance-on-choosing-optimal-cluster-configuration).

## Cloud Native Hybrid reference architecture with Helm Charts

In the Cloud Native Hybrid reference architecture setup, the select _stateless_
components are deployed in Kubernetes by using our official [Helm Charts](https://docs.gitlab.com/charts/).
The _stateful_ components are deployed in compute VMs with the Linux package.

The smallest reference architecture available for use in Kubernetes is the [2k or 40 RPS GitLab Cloud Native Hybrid](2k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) (non HA) and [3k or 60 RPS GitLab Cloud Native Hybrid](3k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) (HA).

For environments that serve fewer users or a lower RPS, you can lower the node specification. Depending on your user count, you can lower all suggested node specifications as desired. However, you should not go lower than the [general requirements](../../install/requirements.md).

## Next steps

Now you have a fresh GitLab environment with core functionality configured accordingly. You might want to configure additional optional GitLab features depending on your requirements. See [Steps after installing GitLab](../../install/next_steps.md) for more information.

{{< alert type="note" >}}

Depending on your environment and requirements, additional hardware requirements or adjustments may be required to set up additional features. See the individual pages for more information.

{{< /alert >}}
