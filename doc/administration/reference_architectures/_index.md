---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Recommended deployment specifications for GitLab at scale.
title: Reference architectures
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The GitLab reference architectures are recommended, production-ready environment designs for deploying GitLab at scale. Each architecture provides detailed specifications that you can use or adapt based on your requirements.

## Before you start

First, consider whether GitLab Self-Managed is the right choice for you and your requirements.

Running any application in production is complex, and the same applies for GitLab. While we aim to make this as smooth as possible, there are still the general complexities based on your design. Typically, you have to manage all aspects such as hardware, operating systems, networking, storage, security, GitLab itself, and more. This includes both the initial setup of the environment and the longer term maintenance.

You must have a working knowledge of running and maintaining applications in production if you decide to go down this route. If you aren't in this position, our [Professional Services](https://about.gitlab.com/services/#implementation-services) team offers implementation services. Those who want a more managed solution long term can explore our other offerings such as [GitLab.com](../../subscriptions/manage_seats.md#gitlabcom-billing-and-usage) or [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md).

If you are considering using the GitLab Self-Managed approach, we encourage you to read through this page in full, specifically the following sections:

- [Deciding which architecture to start with](#deciding-which-architecture-to-start-with)
- [Large monorepos](../../install/sizing.md#large-monorepos)
- [Additional workloads](#additional-workloads)
- [Monitoring and adjusting your environment](#monitoring)

## Deciding which architecture to start with

The reference architectures balance performance, resilience, and cost. They are recommended starting points based on typical workload patterns. However, most deployments will need tuning based on actual usage through [monitoring](#monitoring).

As a general guide, the more performant or resilient you want your environment to be, the more complex it is.

### Expected load

The right architecture size depends primarily on your environment's expected peak load. Requests per second (RPS) is the primary metric for sizing a GitLab infrastructure, but other factors can also apply.

For comprehensive RPS analysis and data-driven sizing decisions, see [reference architecture sizing](../../install/sizing.md), which provides:

- Detailed PromQL queries for extracting peak and sustained RPS metrics
- Workload pattern analysis and RPS composition guidance to identify component-specific adjustments
- Assessment methodology for monorepos, network usage, and growth planning

For quick RPS estimation, some potential options include:

- [Prometheus](../monitoring/prometheus/_index.md#sample-prometheus-queries) queries, such as:

  ```prometheus
  sum(irate(gitlab_transaction_duration_seconds_count{controller!~'HealthController|MetricsController'}[1m])) by (controller, action)
  ```

- [GitLab RPS Analyzer](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/gitlab-rps-analyzer#gitlab-rps-analyzer).
- Other monitoring solutions.
- Load balancer statistics.

If you can't determine your RPS, user count equivalents are provided for Linux package and Cloud Native Hybrid architectures as an alternative sizing method. This count is mapped to typical RPS values, considering both manual and automated usage.

## Available reference architectures

The following reference architectures are available as recommended starting points for your environment.

> [!note]
> Each architecture is designed to be [scalable](#scaling-an-environment). They can be adjusted accordingly based on your workload, upwards or downwards. For example, some known heavy scenarios such as using [large monorepos](../../install/sizing.md#large-monorepos) or notable [additional workloads](#additional-workloads).

### Linux package (Omnibus)

Linux package-based reference architectures deploy all GitLab components on virtual machines with the package. Select components (PostgreSQL, Redis, Object Storage) can optionally use cloud provider services.

The following RPS targets reflect typical workload composition. For atypical workloads, see [Understanding RPS composition](../../install/sizing.md#understanding-rps-composition-and-workload-patterns).

| Size                         | API RPS | Web RPS | Git (Pull) RPS | Git (Push) RPS |
|------------------------------|---------|---------|----------------|----------------|
| [1,000 users](1k_users.md)   | 20      | 2       | 2              | 1              |
| [2,000 users](2k_users.md)   | 40      | 4       | 4              | 1              |
| [3,000 users](3k_users.md)   | 60      | 6       | 6              | 1              |
| [5,000 users](5k_users.md)   | 100     | 10      | 10             | 2              |
| [10,000 users](10k_users.md) | 200     | 20      | 20             | 4              |
| [25,000 users](25k_users.md) | 500     | 50      | 50             | 10             |
| [50,000 users](50k_users.md) | 1000    | 100     | 100            | 20             |

### Cloud Native Hybrid

Cloud Native Hybrid reference architectures deploy select stateless components (Webservice, Sidekiq) in Kubernetes using Helm Charts, while select components remain on virtual machines or use cloud provider services (PostgreSQL, Redis, Object Storage).

| Size                                                                                                 | API RPS | Web RPS | Git (Pull) RPS | Git (Push) RPS |
|------------------------------------------------------------------------------------------------------|---------|---------|----------------|----------------|
| [2,000 users](2k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)   | 40      | 4       | 4              | 1              |
| [3,000 users](3k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)   | 60      | 6       | 6              | 1              |
| [5,000 users](5k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)   | 100     | 10      | 10             | 2              |
| [10,000 users](10k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) | 200     | 20      | 20             | 4              |
| [25,000 users](25k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) | 500     | 50      | 50             | 10             |
| [50,000 users](50k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) | 1000    | 100     | 100            | 20             |

### Cloud Native

Cloud Native architectures deploy all GitLab components in Kubernetes, while PostgreSQL,
Redis, and Object Storage use external managed services. Four standardized sizes cover most
production deployments. For atypical workloads, see [reference architecture sizing](../../install/sizing.md).
This is the recommended architecture for new deployments.

| Size | Target RPS | Workload characteristics |
|------|------------|--------------------------|
| [Small (S)](cloud_native.md#small-s) | ≤100 RPS | Light overall load, not suitable for active monorepos |
| [Medium (M)](cloud_native.md#medium-m) | ≤200 RPS | Moderate load, supports lightly-used monorepos |
| [Large (L)](cloud_native.md#large-l) | ≤500 RPS | Heavy load, handles moderately-used monorepos |
| [Extra Large (XL)](cloud_native.md#extra-large-xl) | ≤1000 RPS | Intensive load, designed for heavily-used monorepos |

> [!note]
> These RPS targets assume typical workload composition. AI-driven usage, such as
> [GitLab Duo Agent Platform](#scaling-for-gitlab-duo-agent-platform), doesn't scale with user
> count and can push actual load above these targets. Monitor actual usage rather than sizing
> from user count alone for environments with meaningful agentic activity.

### If in doubt, start large, monitor, and then scale down

If you're uncertain about the required environment size, consider starting with a larger size, [monitoring](#monitoring) it, and then [scaling down](#scaling-an-environment) accordingly if the metrics support your situation.

Starting large and then scaling down is a prudent approach when:

- You can't determine RPS
- The environment load could be atypically higher than expected
- You have [large monorepos](../../install/sizing.md#large-monorepos) or notable [additional workloads](#additional-workloads)

For example, if you have 3,000 users but also know that there's automation at play that would significantly increase the concurrent load, then you could start with a 100 RPS / 5k User class environment, monitor it, and if the metrics support it, scale down all components at once, or one by one.

### Standalone (non-HA)

For environments serving 2,000 or fewer users, it's generally recommended to follow a standalone approach by deploying a non-HA, single, or multi-node environment. With this approach, you can employ strategies such as [automated backups](../backup_restore/backup_gitlab.md#configuring-cron-to-make-daily-backups) for recovery. These strategies provide a good level of recovery time objective (RTO) or recovery point objective (RPO) while avoiding the complexities that come with HA.

With standalone setups, especially single node environments, various options are available for [installation](../../install/_index.md) and management. The options include [the ability to deploy directly by using select cloud provider marketplaces](https://page.gitlab.com/cloud-partner-marketplaces.html) that reduce the complexity a little further.

### High Availability (HA)

High Availability ensures every component in the GitLab setup can handle failures through various mechanisms. However, to achieve this is complex, and the environments required can be sizable.

For environments serving 3,000 or more users, we generally recommend using an HA strategy. At this level, outages have a bigger impact on more users. All the architectures in this range have HA built in by design for this reason.

#### Do you need High Availability (HA)?

As mentioned previously, achieving HA comes at a cost. The environment requirements are sizable as each component needs to be multiplied, which comes with additional actual and maintenance costs.

For a lot of our customers with fewer than 3,000 users, we've found that a backup strategy is sufficient and even preferable. While this does have a slower recovery time, it also means you have a much smaller architecture and less maintenance costs as a result.

As a general guideline, employ HA only in the following scenarios:

- When you have 3,000 or more users.
- When GitLab being down would critically impact your workflow.

#### Scaled-down High Availability (HA) approach

If you still need HA for fewer users, you can achieve it with an adjusted [3K architecture](3k_users.md#supported-modifications-for-lower-user-counts-ha).

#### Zero-downtime upgrades

[Zero-downtime upgrades](../../update/zero_downtime.md) are available for standard environments with HA (Cloud Native Hybrid is [not supported](https://gitlab.com/groups/gitlab-org/cloud-native/-/work_items/52)). This allows for an environment to stay up during an upgrade. However, this process is more complex as a result and has some limitations as detailed in the documentation.

When going through this process, it's worth noting that there may still be brief moments of downtime when the HA mechanisms take effect.

In most cases, the downtime required for doing an upgrade shouldn't be substantial. Use this approach only if it's a key requirement for you.

### GitLab Geo (Cross Regional Distribution / Disaster Recovery)

With [GitLab Geo](../geo/_index.md), you can achieve distributed environments in
different regions with a full Disaster Recovery (DR) setup in place. GitLab Geo
requires at least two separate environments:

- One primary site.
- One or more secondary sites that serve as replicas.

If the primary site becomes unavailable, you can fail over to one of the secondary sites.

> [!note]
> Use this advanced and complex setup only if DR is
> a key requirement for your environment. You must also make additional decisions
> on how each site is configured. For example, if each secondary site would be the
> same architecture as the primary or if each site is configured for HA.

### Large monorepos / Additional workloads

[Large monorepos](../../install/sizing.md#large-monorepos) or significant [additional workloads](#additional-workloads) can affect the performance of the environment notably. Some adjustments may be required depending on the context.

For comprehensive analysis of these factors, see [reference architecture sizing](../../install/sizing.md), which provides:

- Detailed assessment methodology for monorepo impacts on infrastructure.
- Component-specific scaling recommendations for different workload patterns.
- Network bandwidth analysis for heavy data transfer scenarios.

If this situation applies to you, reach out to your GitLab representative or our [Support team](https://about.gitlab.com/support/)
for further guidance.

### Cloud provider services

For all the previously described strategies, you can run select GitLab components on equivalent cloud provider services such as the PostgreSQL database or Redis/Valkey.

For more information, see [Infrastructure and services](#infrastructure-and-services).

### Decision Tree

Read through the guidance documented previously in full first before you refer to the following decision tree.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TD
    accTitle: Decision tree for reference architecture selection
    accDescr: Key considerations for selecting architecture type and size, including Gitaly Cluster requirements, expected load, and HA requirements.

   L0A(<b>What Reference Architecture should I use?</b>)

   L_CNQ("Do you need Gitaly Cluster (Praefect)<br>for repository-level HA?")
   L_CN><b>Recommendation</b><br><br>Cloud Native architecture<br>Select the size closest to your RPS]

   L1A(<b>What is your expected load?</b>)
   L2A("60 RPS / 3,000 users or more?")
   L2B("40 RPS / 2,000 users or less?")

   L3A("Do you need HA?<br>(or zero-downtime upgrades)")
   L3B[Do you have experience with<br/>and want additional resilience<br/>with select components in Kubernetes?]

   L4A><b>Recommendation</b><br><br>60 RPS / 3,000 user architecture with HA<br>and supported reductions]
   L4B><b>Recommendation</b><br><br>Architecture closest to expected load with HA]
   L4C><b>Recommendation</b><br><br>Cloud Native Hybrid architecture<br>closest to expected load]
   L4D>"<b>Recommendation</b><br><br>Standalone 20 RPS / 1,000 user or 40 RPS / 2,000 user<br/>architecture with Backups"]

   L0A --> L_CNQ
   L_CNQ -->|No| L_CN
   L_CNQ -->|Yes| L1A
   L1A --> L2A
   L1A --> L2B
   L2A -->|Yes| L3B
   L3B -->|Yes| L4C
   L3B -->|No| L4B

   L2B --> L3A
   L3A -->|Yes| L4A
   L3A -->|No| L4D

   L5A("Do you need cross regional distribution</br> or disaster recovery?") --> |Yes| L6A><b>Additional Recommendation</b><br><br> GitLab Geo]
   L_CN ~~~ L5A
   L4A ~~~ L5A
   L4B ~~~ L5A
   L4C ~~~ L5A
   L4D ~~~ L5A

   L5B("Do you have Large Monorepos or expect</br> to have substantial additional workloads?") --> |Yes| L6B><b>Additional Recommendations</b><br><br>Start large, monitor and scale down<br><br> Contact GitLab representative or Support]
   L_CN ~~~ L5B
   L4A ~~~ L5B
   L4B ~~~ L5B
   L4C ~~~ L5B
   L4D ~~~ L5B

```

## Requirements

Before implementing a reference architecture, see [installation requirements](../../install/requirements.md)
for hardware, component, and infrastructure requirements, and
[reference architecture sizing](../../install/sizing.md) for workload assessment methodology.

### Additional workloads

These architectures have been [designed and tested](#how-specifications-are-derived) for standard GitLab
setups based on real data.

However, additional workloads can multiply the impact of operations by triggering follow-up actions.
You might have to adjust the suggested specifications to compensate if you use:

- Security software on the nodes.
- Hundreds of concurrent CI jobs for [large repositories](../../user/project/repository/monorepos/_index.md).
- Custom scripts that [run at high frequency](../logs/log_parsing.md#print-top-api-user-agents).
- [Integrations](../../integration/_index.md) in many large projects.
- [Feature flags](../../operations/feature_flags.md#performance-factors) in projects with large user bases.
- [Server hooks](../server_hooks.md).
- [System hooks](../system_hooks.md).

Generally, you should have robust monitoring in place to measure the impact of any additional workloads to
inform any changes needed to be made. Reach out to your GitLab representative or our [Support team](https://about.gitlab.com/support/)
for further guidance.

## Infrastructure and services

These architectures run on any infrastructure that meets the specifications, whether on a cloud provider or
on-premises. For supported infrastructure and Kubernetes requirements, see
[installation requirements](../../install/requirements.md#supported-infrastructure).

For managed cloud provider services for PostgreSQL, Redis/Valkey, and object storage, see
[cloud services for GitLab components](../../install/cloud-services.md).

## Deviating from the suggested reference architectures

The further away you move from the reference architectures,
the harder it is to get support. With each deviation, you introduce
a layer of complexity that complicates troubleshooting potential
issues.

These architectures use the official Linux packages or [Helm Charts](https://docs.gitlab.com/charts/) to
install and configure the various components. The components are
installed on separate machines (virtualized or Bare Metal). Machine hardware
requirements are listed in the "Configuration" columns on specific reference architecture pages. Equivalent VM standard sizes are listed
in the GCP/AWS/Azure columns of each [available architecture](#available-reference-architectures).

You can run GitLab components on Docker, including Docker Compose. Docker is well supported and provides consistent specifications across environments.
However, it is still an additional layer and might add some support complexities. For example, not being able to run `strace` in containers.

### Unsupported designs

While we try to have a good range of support for GitLab environment designs, certain approaches don't work effectively. The following sections detail these unsupported approaches.

#### Stateful components in Kubernetes

[Running stateful components in Kubernetes, such as Postgres and Redis, is not supported](https://docs.gitlab.com/charts/installation/#configure-the-helm-chart-to-use-external-stateful-data).

You can use other supported cloud provider services, unless specifically called out as unsupported.

Individual Gitaly nodes can be deployed on Kubernetes and are generally available. This provides a non-HA solution where each repository is stored on a single node. For context on Gitaly deployment options and limitations, see [Gitaly on Kubernetes](../gitaly/kubernetes.md#context).

For reference architectures that deploy Gitaly in Kubernetes as part of a fully cloud-native setup, see [Cloud Native reference architectures](cloud_native.md).

#### Deploying one environment over multiple regions

GitLab does not support deploying a single environment across multiple regions. These setups can result in significant issues, such as excessive network latency or split-brain scenarios if connectivity between regions fails.

Several GitLab components perform synchronous replication or require an odd number of nodes to function correctly, such as Consul, Redis Sentinel, and Praefect. Distributing these components across multiple regions with high latency can severely impact their functionality and the overall system performance.

This limitation applies to all potential GitLab environment setups, including Cloud Native Hybrid alternatives.

For deploying GitLab over multiple data centers or regions, we offer [GitLab Geo](../geo/_index.md) as a comprehensive solution.

## How specifications are derived

Specifications are informed by real customer data and ad-hoc performance testing.

### How we perform the tests

Testing is conducted using specific coded workloads derived from sample customer data, utilizing both the [GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) for environment deployment with Terraform and Ansible, and the [GitLab Performance Tool (GPT)](https://gitlab.com/gitlab-org/quality/performance) for performance testing with k6.

Testing is performed primarily on GCP and AWS using their standard compute offerings (n1 series for GCP, m5 series for AWS) as baseline configurations. These machine types were selected as a lowest common denominator target to ensure broad compatibility. Specifications are calibrated on standard general-purpose x86 compute - any machine type meeting or exceeding the vCPU and memory requirements is expected to work, including newer CPU generations and ARM-based instances. The architectures are expected to perform similarly on any hardware meeting the specifications, whether on other cloud providers or on-premises.

### Performance targets

Each reference architecture is tested against specific throughput targets based on real customer data. For every 1,000 users, we test:

- API: 20 RPS
- Web: 2 RPS
- Git (Pull): 2 RPS
- Git (Push): 0.4 RPS (rounded to the nearest integer)

The listed RPS targets were selected based on real customer data of total environmental loads corresponding to the user count, including CI and other workloads.

> [!note]
>
> - These RPS breakdowns represent test targets based on typical workload patterns. Your actual workload composition may
>   vary. For guidance on assessing your specific RPS composition and when adjustments are needed, see
>   [Understanding RPS composition](../../install/sizing.md#understanding-rps-composition-and-workload-patterns).
> - Network latency between components in test environments was observed at <5 ms but note this is not intended as a hard requirement.

### Test coverage and results

Testing is designed to be effective and provide good coverage for the reference architecture targets, spanning Linux package and Cloud Native environments. The specific environments and configurations tested are reviewed regularly to ensure the best coverage and cost-to-value balance, and may change over time.

Our testing also includes prototype variations of these architectures being explored for potential future inclusion. Test results are publicly available on the [Reference Architecture wiki](https://gitlab.com/gitlab-org/reference-architectures/-/wikis/Benchmarks/Latest).

## Maintaining a reference architecture environment

Maintaining a reference architecture environment is generally the same as any other GitLab environment.

In this section you can find links to documentation for relevant areas and specific architecture notes.

### Scaling an environment

The reference architectures are designed as validated starting points based on typical workload patterns, not final configurations. Most production deployments benefit from adjustments based on actual usage patterns that emerge through monitoring. The architectures are scalable throughout, and you can tune them iteratively as your workload characteristics become clear. Scaling can be done component-by-component or wholesale to the next architecture size when metrics indicate sustained resource pressure.

> [!note]
> If a component is continuously exhausting its given resources, reach out to our [Support team](https://about.gitlab.com/support/) before performing any significant scaling.

#### When to scale

Most deployments benefit from adjustments after observing actual workload patterns. Common scenarios that trigger scaling include:

**Resource sizing adjustments:**

- Increasing Webservice/Rails capacity for API-heavy workloads, particularly when API traffic exceeds 90% of total RPS (see [Understanding RPS composition](../../install/sizing.md#understanding-rps-composition-and-workload-patterns))
- Scaling Gitaly for monorepo-heavy environments or when repository sizes exceed 2 GB (see [Identify component adjustments](../../install/sizing.md#identify-component-adjustments))
- Adjusting Sidekiq workers for high CI/CD throughput or heavy background job processing

**Configuration tuning:**

- Setting Gitaly repository cgroup counts based on concurrent access patterns (see [Gitaly cgroups](../gitaly/cgroups.md))
- Configuring Sidekiq queue priorities for job processing optimization (see [processing specific job classes](../sidekiq/processing_specific_job_classes.md))

**Architecture refinements:**

- Adding PostgreSQL read replicas for read-heavy workloads
- Splitting Sidekiq into specialized pools for different job types
- Adjusting minimum instance counts for environments with sharp traffic spikes

These adjustments are typical and expected. Reference architectures provide the foundation, but monitoring your specific workload determines the optimal configuration. For systematic assessment of your environment, see [reference architecture sizing](../../install/sizing.md).

#### Scaling for GitLab Duo Agent Platform

GitLab Duo Agent Platform introduces additional infrastructure requirements beyond standard GitLab workloads. Agent Platform workflows execute through the GitLab Rails API, process jobs asynchronously through Sidekiq, and access repository data for code context and analysis.

Agent Platform usage scales with automation and agent activity, not user count, so it doesn't
follow the traffic patterns the reference architecture RPS targets are based on. An environment
sized correctly for its user count can still come under sustained resource pressure from
agentic workloads. Monitor the components below directly rather than assuming standard sizing
accounts for Agent Platform usage.

Primary component impacts:

- **Rails (Webservice/Puma)** - Agent Platform API requests add to overall request load and WebSocket connections for streaming AI responses are managed by Workhorse
- **Sidekiq** - AI completion jobs and workflow state updates are processed as background jobs
- **PostgreSQL** - Agent workflow sessions and state data are stored in the database
- **Gitaly** - Repository file access for code context and commit operations for agent-generated changes

For environments planning Agent Platform adoption:

- Deploy the recommended architecture size based on your standard workload RPS
- Monitor Rails CPU utilization during initial rollout
- Monitor Sidekiq CPU utilization and job queue depths
- Monitor PostgreSQL for increased transaction rates from workflow state management
- Monitor Gitaly for increased file access patterns from code analysis features

For example Prometheus queries to monitor these components, see [sample Prometheus queries](../monitoring/prometheus/_index.md#sample-prometheus-queries).

If you observe sustained resource pressure, increase capacity by scaling the affected components. In Kubernetes deployments, increase pod replicas and node pool capacity. In Linux package deployments, scale horizontally by adding nodes or vertically by increasing node specifications.

Resource requirements vary based on Agent Platform usage intensity and specific features enabled. Treat the recommended architecture size as a starting point for Agent Platform adoption, not a guarantee of sufficient headroom, and scale based on observed metrics.

#### How to scale

For most components, vertical and horizontal scaling can be applied as usual. However, before doing so, be aware of the following caveats:

- When scaling Puma or Sidekiq vertically, the amount of workers must be adjusted to use the additional specifications. Puma worker counts are typically adjusted automatically, but Sidekiq may require [manual configuration](../sidekiq/extra_sidekiq_processes.md#start-multiple-processes).
- Redis and PgBouncer are primarily single threaded. If these components are seeing CPU exhaustion, they might have to be scaled out horizontally.
- In Linux package deployments, the Consul, Redis Sentinel, and Praefect components require an odd number of nodes for a voting quorum when deployed in HA form.
- Scaling certain components significantly can result in notable knock on effects that affect the performance of the environment. For more guidance, see [Scaling knock on effects](#scaling-knock-on-effects).

Conversely, if you have robust metrics in place that show the environment is over-provisioned, you can scale downwards.
You should take an iterative approach when scaling downwards, to ensure there are no issues.

#### Scaling knock on effects

In some cases, scaling a component significantly may result in knock on effects for downstream components, impacting performance. The architectures are designed with balance in mind to ensure components that depend on each other are congruent in terms of specifications. Notably scaling a component may result in additional throughput being passed to the other components it depends on. As a result, you could have to scale these other dependent components as well. To determine this, monitor the saturation metrics of all dependent services before scaling. If multiple interdependent components show saturation, they should be scaled together in a coordinated manner rather than sequentially, preventing bottlenecks from simply shifting between components.

> [!note]
> The architectures have been designed to have elasticity to accommodate an upstream component being scaled. However, reach out to our [Support team](https://about.gitlab.com/support/) before you make any significant changes to your environment to be safe.

The following components can impact others when they have been significantly scaled:

- Puma and Sidekiq - Notable scale ups of either Puma or Sidekiq workers will result in higher concurrent connections to the internal load balancer, PostgreSQL (via PgBouncer if present), Gitaly (via Praefect if present) and Redis.
  - Redis is primarily single-threaded. In some cases, you might have to split Redis into separate instances (for example, cache and persistent) if the increased throughput causes CPU exhaustion in a combined cluster.
  - PgBouncer is also single threaded but a scale out might result in a new pool being added that in turn might increase the total connections to Postgres. It's strongly recommended to only do this if you have experience in managing Postgres connections and to seek assistance if in doubt.
- Gitaly Cluster (Praefect)/PostgreSQL - A notable scale out of additional nodes can have a detrimental effect on the HA system and performance due to increased replication calls to the primary node.

#### Scaling from a non-HA to an HA architecture

In most cases, vertical scaling is only required to increase an environment's resources. However, if you are moving to an HA environment,
additional steps are required for the following components to switch over to their HA forms.

For more information, see the following documentation:

- [Redis to multi-node Redis w/ Redis Sentinel](../redis/replication_and_failover.md#switching-from-an-existing-single-machine-installation)
- [Postgres to multi-node Postgres w/ Consul + PgBouncer](../postgresql/moving.md)
- [Gitaly to Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)

### Upgrades

Upgrading a reference architecture environment is the same as any other GitLab environment. For more information, see
[upgrade GitLab](../../update/_index.md). [Zero-downtime upgrades](#zero-downtime-upgrades) are also available.

> [!note]
> You should upgrade a reference architecture in the same order as you created it.

### Monitoring

You can monitor your infrastructure and [GitLab](../monitoring/_index.md) using various options. See the selected monitoring solution's documentation for more information.

> [!note]
> GitLab application is bundled with [Prometheus and various Prometheus compatible exporters](../monitoring/prometheus/_index.md) that could be hooked into your solution.

## Update history

You can find a full history of changes [on the GitLab project](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&label_name%5B%5D=Reference%20Architecture&label_name%5B%5D=documentation).
