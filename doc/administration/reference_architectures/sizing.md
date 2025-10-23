---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Guide to define Reference Architecture size and component-specific adjustments.
title: Assess reference architecture size
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To select an appropriate reference architecture, you should use a systematic approach for assessing and sizing GitLab
environments based on reference architectures.

To determine the appropriate reference architecture and any required component-specific adjustments, the following
information helps you analyze:

- Requests per second (RPS) patterns.
- Workload characteristics.
- Resource saturation.

## Before you begin

You can use this information if you have a complex environment to select an appropriate reference architecture.
You might not require this level of detail, and you can assess the size of your environment by using the
[information for less complex environments](_index.md).

{{< alert type="note" >}}

Need expert guidance? Sizing your architecture correctly is critical for optimal performance. Our
[Professional Services](https://about.gitlab.com/professional-services/) team can evaluate your specific architecture
and provide tailored recommendations for performance, stability, and availability optimization.

{{< /alert >}}

To follow this documentation, you must have Prometheus monitoring deployed with the GitLab instance. Prometheus
provides the accurate metrics required for proper sizing assessment.

If you haven't yet configured Prometheus:

1. Configure monitoring with [Prometheus](../monitoring/prometheus/_index.md). Reference architecture documentation
   provides details on Prometheus configuration for each environment size. For cloud-native GitLab, you can use the
   [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) Helm chart
   to configure metrics scraping.
1. Collect data for 7-14 days to gather meaningful data patterns.
1. Read the rest of this information.

If you can't configure Prometheus monitoring:

- [Compare current environment](#analyze-current-environment-and-validate-recommendations) specifications to the nearest
  reference architecture to estimate sizing.
- Use the [`get-rps.rb` script](https://gitlab.com/gitlab-com/support/toolbox/dotfiles/-/blob/main/scripts/get-rps.rb)
  for basic peak RPS extraction from logs. Log analysis has significant limitations. It provides less reliable data than
  metrics and not available for cloud-native GitLab.

If migrating from other platforms, the following PromQL queries cannot be applied without existing GitLab metrics.
However, the general assessment methodology remains valid:

1. Estimate the nearest reference architecture based on expected workload.
1. Identify anticipated additional workloads.
1. Assess number of large repositories
1. Incorporate growth projections.
1. Select a reference architecture with
   [appropriate buffer](_index.md#if-in-doubt-start-large-monitor-and-then-scale-down).

### Running PromQL queries

Running PromQL queries depends on the monitoring solution you use. As noted in
[Prometheus monitoring documentation](../monitoring/prometheus/_index.md#how-prometheus-works), monitoring data can be
accessed either by connecting directly to Prometheus or by using a dashboard tool like Grafana.

## Determine your baseline size

Requests per second (RPS) is the primary metric for sizing GitLab infrastructure. Different traffic types (API, Web, Git
operations) stress different components, so each is analyzed separately to find true capacity requirements.

### Extract peak traffic metrics

Run these queries to understand your maximum load. These queries show you:

- Absolute peaks, which are the highest spike you've seen. Absolute peaks show worst-case scenarios.
- Sustained peaks, which are the 95th percentile and considered - your typical "busy" level. Sustained peaks reveal
  typical high-load periods.

If absolute peaks are rare anomalies, sizing for sustained load may be appropriate.

Adjust time ranges in queries based on retention (change `[7d]` to `[30d]` if longer history available).

#### Query absolute peaks

To identify maximum observed RPS over the specified time period:

1. Run these queries:

   - API traffic peak, to measure peak API requests from automation, external tools, and webhooks:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))[7d:1m]
     )
     ```

   - Web traffic peak, to measure peak UI interactions from users in browsers:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController"}[1m]))[7d:1m]
     )
     ```

   - Git pull and clone peak, to measure peak repository clone and fetch operations:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Git push peak, to measure peak code push operations:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. Record the results.

#### Query sustained peaks

To identify typical high-load levels, filtering out rare spikes:

1. Run these queries:

   - API sustained peak:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))[7d:1m]
     )
     ```

   - Web sustained peak:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController"}[1m]))[7d:1m]
     )
     ```

   - Git pull and clone sustained peak:

     ```prometheus
     quantile_over_time(0.95,
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Git push sustained peak:

     ```prometheus
     quantile_over_time(0.95,
      (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
      sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. Record the results.

### Map traffic to reference architectures

To map traffic to reference architectures, using the results you recorded earlier:

1. Consult the [initial sizing guide](_index.md#initial-sizing-guide) to see which reference architecture each traffic
   type suggests.
1. Fill in an analysis table. Use the following table as a guide:

   | Traffic type       | Peak RPS | Peak suggested RA     | Sustained RPS | Sustained suggested RA |
   |:-------------------|:---------|:----------------------|:--------------|:-----------------------|
   | API                | ________ | _____ (up to ___ RPS) | _____________ | _____ (up to ____ RPS) |
   | Web                | ________ | _____ (up to ___ RPS) | _____________ | _____ (up to ____ RPS) |
   | Git pull and clone | ________ | _____ (up to ___ RPS) | _____________ | _____ (up to ____ RPS) |
   | Git push           | ________ | _____ (up to ___ RPS) | _____________ | _____ (up to ____ RPS) |

1. Compare all reference architectures in the **Peak Suggested RA** column and select the largest size. Repeat for
   the **Sustained Suggested RA** column.
1. Document the baseline:
   - Largest peak RA suggested.
   - Largest sustained RA suggested.

### Choose a reference architecture

At this point, there are two candidate reference architecture sizes:

- One based on absolute peaks.
- One based on sustained load.

To choose a reference architecture:

1. If peak and sustained suggest the same RA, use that RA.
1. If peak suggests a larger RA than sustained. Calculate the gap. Is peak RPS within 10-15% of the sustained RA's upper
   limit?

General guidelines:

- If peak RPS exceeds the sustained RA limit by less than 10-15%, sustained RA can be considered with acceptable risk
  because reference architectures have built-in headroom.
- Beyond 15%, start with the peak-based RA, then monitor and adjust if metrics support downsizing.
  - Example 1: Peak is 110 RPS, Large RA handles "up to 100 RPS" → 10% over → Large should suffice (Reference architectures have built-in headroom)
  - Example 2: Peak is 150 RPS, Large RA handles "up to 100 RPS" → 50% over → Use X-Large (up to 200 RPS)

For environments under 40 RPS and where high availability (HA) is a requirement, consult the
[high availability section](_index.md#high-availability-ha) to identify whether switching to the 60 RPS / 3,000 user
architecture with supported reductions is needed.

### Before you proceed

Having completed this section, you've established your baseline reference architecture size. This forms the foundation,
but the following sections identify whether specific workload requires component adjustments beyond the standard configuration.

Before proceeding, ensure you've documented the details you've gathered in this section. You can use the following as a
guide:

```markdown
Reference architecture assessment summary:

- Selected reference architecture: _____
- Justification based on _____ RPS [absolute/sustained]

| Traffic Type       | Peak RPS | Sustained RPS (95th) |
|:-------------------|:---------|:---------------------|
| API                | ________ | ____________________ |
| Web                | ________ | ____________________ |
| Git pull and clone | ________ | ____________________ |
| Git push           | ________ | ____________________ |

Highest RPS Peak timestamp for workload analysis: _____
```

## Identify component adjustments

Workload assessment identifies specific usage patterns that require component adjustments beyond the base reference
architecture. While RPS determines overall size, workload patterns determine the shape. Two environments with identical
RPS can have vastly different resource needs.

Different workloads stress different parts of GitLab architecture:

- CI/CD-heavy environments processing thousands of jobs while maintaining moderate RPS stress Sidekiq and Gitaly.
- Environments with extensive API automation showing high RPS but concentrating load on database and Rails layers.

### Analyze top endpoints during peak load

Using the peak timestamp from the earlier section, identify which endpoints received the most traffic during maximum load.

{{< alert type="note" >}}

If your RPS metrics show consistently high traffic during off-hours (>50% of peak), this suggests heavy automation
beyond typical patterns. For example, peak traffic that reaches 100 RPS during business hours but maintains 50+ RPS during
nights and weekends indicates significant automated workload. Consider this when
[evaluating component adjustments](#determine-component-adjustments).

{{< /alert >}}

1. Run this query with visualization enabled (bar chart for distribution over time, or pie chart for general distribution):

   ```prometheus
   topk(20,
     sum by (controller, action) (
       rate(gitlab_transaction_duration_seconds_count{controller!~"HealthController|MetricsController", action!~".*/internal/.*"}[1m])
     )
   )
   ```

1. Review the results for the distribution of top endpoints during the absolute RPS peak. The results might have:

   - No visible endpoint pattern. In this case, continue with reference architecture selected earlier. Ensure robust
     monitoring is in place to measure the impact of any workload changes.
   - A majority of heavy API usage for non-Git traffic. In this case, webhooks and issue, group, and project API calls
     indicate a database-intensive pattern.
   - A majority of Git- or Sidekiq-related endpoints. In this case, merge request diffs, pipeline jobs, branches, commits,
     file operations, CI/CD jobs, security scanning, and import operations indicate a Sidekiq/Gitaly-intensive pattern.

1. Record findings:

   ```markdown
   Workload pattern identified:

   - [ ] Database-intensive
   - [ ] Sidekiq- or Gitaly-intensive
   - [ ] None detected
   ```

### Determine component adjustments

The indicators above provide initial signals of additional workloads. Because of built-in headroom in reference
architectures, these workloads may be handled without adjustments. However, if strong indicators exist and high levels
of automation are known, consider the following adjustments.

Based on the workload pattern identified earlier, different components require scaling:

| Workload type              | When to apply                                                                                                                                                                                | Components to scale |
|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------|
| Database-intensive         | <ul><li>Heavy API usage for non-Git traffic (webhooks, issues, groups, and projects)</li><li>Known [extensive automation or integration workloads](_index.md#additional-workloads)</li></ul> | <ul><li>Increase Rails resources</li><li>[Database scaling](#database-scaling)</li><ul> |
| Sidekiq/Gitaly-intensive** | <ul><li>Heavy Git operations, CI/CD jobs, security scanning, import operations, and Git server hooks</li><li>Known CI/CD-heavy usage patterns</li></ul>                                      | <ul><li>Increase Sidekiq specifications</li><li>Gitaly vertical scaling</li><li>[Database scaling](#database-scaling)</li><li>Advanced: Configure specific [job classes](../sidekiq/processing_specific_job_classes.md)</li></ul> |

#### Scaling guidance

Resource adjustments vary based on workload intensity and saturation metrics:

1. Start with 1.25x-1.5x current resources.
1. Refine based on monitoring data after implementation.

If you are planning to deploy cloud-native GitLab, workload patterns identified in this assessment have additional
implications for Kubernetes configuration:

- High off-hours traffic. Ensure minimum pod counts are sufficient for baseline load rather than allowing scale-to-zero
  during quiet periods. For example, with 100 RPS during business hours and consistent 50 RPS at night caused by
  automation, minimum pod count configuration needs to align with baseline off-hours load.
- Rapid traffic spikes. Default HPA settings may not scale fast enough. Monitor pod scaling behavior during initial
  rollout to prevent request queuing during these transitions. For example, a rapid spike from 50 to 200 RPS caused by
  ramping up from quiet to working hours or a specific automation spike.

##### Database scaling

Database scaling strategy depends on workload characteristics and might require multiple approaches:

1. Vertical scaling to address immediate capacity constraints, which:
   - Is required for write-heavy workloads because replicas don't reduce primary load.
   - Provides immediate capacity increase for both read and write operations.
1. [Database load balancing](../postgresql/database_load_balancing.md) (recommended) with read replicas, which:
   - Is especially beneficial for read-heavy workloads (85-95% reads).
   - Distributes read traffic across multiple nodes.
   - Can be added in combination with vertical scaling.
1. Continue vertical scaling if write performance remains a bottleneck.

Use this Prometheus query to identify read/write distribution:

```prometheus
# Percentage of READ operations
(
  (sum(rate(gitlab_transaction_db_count_total[5m])) - sum(rate(gitlab_transaction_db_write_count_total[5m]))) /
  sum(rate(gitlab_transaction_db_count_total[5m]))
) * 100
```

### Before you proceed

Having completed this section, you've identified workload patterns and determined any required component adjustments.

Before you proceed, record the complete workload assessment:

```markdown
Workload pattern identified:

- [ ] Database-intensive
- [ ] Sidekiq- or Gitaly-intensive
- [ ] None detected
- Component adjustments needed: _____
```

In the next section, you assess special data characteristics that might require additional infrastructure considerations.

## Assess special infrastructure requirements

Repository characteristics and network usage patterns can significantly impact GitLab performance beyond what RPS metrics
reveal.

Large monorepos, extensive binary files, and network-intensive operations require infrastructure adjustments that
standard sizing doesn't account for.

### Large monorepos

Large monorepos (several gigabytes or more) fundamentally change how Git operations perform. A single clone of a 10 GB
repository consumes more resources than hundreds of clones of typical repositories.

These repositories affect not just Gitaly, but also Rails, Sidekiq, and the database depending on the workload.

The profiling process focuses on identifying repositories that significantly exceed typical sizes:

- Medium monorepos: 2 GB - 10 GB. These require modest adjustments.
- Large monorepos: >10 GB. These require significant infrastructure changes.

To identify a repository's size:

1. Go to a project's [usage quotas](../../user/storage_usage_quotas.md#view-storage).
1. Review the [**Repository** storage type](../../user/project/repository/repository_size.md).
1. Calculate the number of projects with repositories larger than 2 GB and larger than 10 GB.
1. Record the results:

   ```plaintext
   Number of medium monorepos (2GB - 10GB): _____
   Number of large monorepos (>10GB): _____
   ```

#### Infrastructure adjustments for monorepos

Large repositories require both vertical scaling and operational adjustments. These repositories affect performance
across the entire stack, from Git operations and CPU usage to memory consumption and network bandwidth.

| Scenario                 | Component adjustments |
|:-------------------------|:----------------------|
| Several medium monorepos | <ul><li>Gitaly: 1.5x-2x specifications</li><li>Rails: 1.25x-1.5x specifications</li></ul> |
| Large monorepos          | <ul><li>Gitaly: 2x-4x specifications</li><li>Rails: 1.5x-2x specifications</li><li>Consider sharding monorepo to dedicated Gitaly node</li></ul> |

Additional optimization strategies for monorepo environments are documented in [Improving monorepo performance](../../user/project/repository/monorepos/_index.md), including Git LFS for binary files and shallow cloning.

### Network-heavy workloads

Network saturation causes unique problems that are often difficult to diagnose. Unlike CPU or memory bottlenecks that
affect specific operations, network saturation can cause seemingly random timeouts across all GitLab functions.

Common network load sources:

- Heavy container registry usage (large images, frequent pulls).
- LFS operations (binary files, media assets).
- Large CI/CD artifacts (build outputs, test results).
- Monorepo clones (especially in CI/CD pipelines).

#### Measure network usage

Calculate peak network consumption to identify potential bottlenecks.

1. Run the following queries:

   ```prometheus
   # Outbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))


   # Inbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))

   ```

1. Record the results:

   ```plaintext
   Max outbound traffic: _____ Gbps
   Max inbound traffic: _____ Gbps
   ```

#### Network capacity requirements

The thresholds below are approximate guidelines only. Actual network bandwidth guarantees vary significantly by cloud
provider and VM type. Always verify the network specifications (baseline and burst limits) for your specific instance
types to ensure they align with your workload patterns.

Based on outbound and inbound traffic measurements:

| Network load | Threshold | Why this threshold                                                 | Action required |
|:-------------|:----------|:-------------------------------------------------------------------|:----------------|
| Standard     | <1 Gbps   | Within baseline bandwidth of most standard instances               | Standard instances sufficient |
| Moderate     | 1-3 Gbps  | May exceed AWS baseline but within GCP/Azure standard instances    | <ul><li>AWS: Monitor for throttling, might need network-enhanced</li><li>GCP/Azure: Standard instances usually sufficient</li></ul> |
| High         | 3-10 Gbps | Exceeds AWS baseline. Approaches limits of some standard instances | <ul><li>AWS: Network-enhanced VMs required</li><li>GCP/Azure: Verify instance bandwidth specifications</li></ul> |
| Very High    | >10 Gbps  | Exceeds most standard instance capabilities                        | <ul><li>Network-enhanced VMs required across all providers</li><li>For large artifacts, disable [object proxy download](../object_storage.md#proxy-download)</li></ul> |

### Before you proceed

Before you proceed, record the complete data profiling assessment:

```txt
Data Profile Summary:
- Medium monorepos (2GB-10GB): _____
- Large monorepos (>10GB): _____
- Gitaly adjustments needed: _____
- Rails adjustments needed: _____
- Peak outbound traffic: _____ Gbps
- Peak inbound traffic: _____ Gbps
- Network infrastructure changes: _____
```

## Analyze current environment and validate recommendations

Understanding the existing environment provides crucial context for recommendations:

- If the current environment handles workload without performance issues, it serves as valuable validation for sizing
  estimates.
- Conversely, environments with performance problems require careful analysis to avoid perpetuating under-sizing.

### Document the current environment

Collect comprehensive environment data to establish the current state:

- Architecture details:
  - Type: high availability (HA) or non-high availability (non-HA).
  - Deployment method: Linux package or cloud-native GitLab.
- Component specifications:
  - Node count and specifications for each component.
  - Custom configurations or deviations.

### Identify nearest reference architecture

1. Compare the current environment to [available reference architectures](_index.md). Consider the following:

   - Total compute resources per component.
   - Node distribution and architecture pattern (HA vs non-HA).
   - Component specifications relative to reference architecture sizes.

1. Record your findings:

   ```plaintext
   Nearest Reference Architecture: _____
   Custom configurations or deviations:
   - _____
   - _____
   ```

### Compare current environment to recommended architecture

Compare the current environment against the recommended reference architecture you developed from the previous sections.
If the current environment:

- Has no performance issues and current resources < recommended RA:
  - Recommendations are conservative and provide future headroom.
  - Proceed with recommended RA.
  - Monitor post-implementation for potential optimization opportunities.
- Has no performance issues and current resources ≈ recommended RA:
  - Strong validation of your sizing assessment.
  - Current environment confirms recommended size is appropriate.
- Has no performance issues and current resources > recommended RA:
  - Current environment might be over-provisioned or has valid reasons for additional resources that need to be analysed.
    Check CPU/memory [resource utilization](../monitoring/prometheus/_index.md#sample-prometheus-queries) on Rails,
    Gitaly, the database, and Sidekiq.

    Low utilization (<40%) suggests over-provisioning. High utilization might indicate specific workload requirements
    not captured in RPS analysis.
  - Review whether recommendations need adjustment for undiscovered requirements.

If current environment has performance issues:

- Use current specifications as minimum baseline only. Recommendations from earlier sections should exceed current
  specifications.
- If recommendations are significantly lower than current, investigate:
  - Workload patterns not captured in the assessment.
  - Component-specific bottlenecks requiring targeted scaling.

### Before you proceed

Having completed this section, you've analyzed the current environment and compared against recommendations.

Before you proceed, record the complete environment comparison:

```plaintext
Current Environment Analysis:
- Current RA (nearest): _____
- Recommended RA (from RPS and workload analysis): _____
- Resource comparison: [ ] Current < Recommended [ ] Current ≈ Recommended [ ] Current > Recommended
- Performance status: [ ] No issues [ ] Has issues
- Adjustments needed: _____
- Notes: _____
```

In the next section, you assess growth projections to ensure sizing remains appropriate over time.

## Plan for future capacity

Infrastructure changes require significant lead time for procurement, migration, and testing. Growth estimation ensures
the recommended architecture remains viable throughout the implementation period and beyond.

Historical trends combined with business plans provide the most accurate growth projections.

### Analyze historical growth patterns

Past growth patterns can help to predict future trajectory better than business projections:

1. Compare current RPS to 6-12 months prior using information in [your baseline size](#determine-your-baseline-size).
1. Identify growth acceleration or deceleration trends.

### Incorporate business planning factors

Expected business changes that impact infrastructure needs:

- Team expansion or consolidation.
- New project developments.
- Increased development activity on existing projects.

Evaluate whether any of these factors (or other organizational changes) could affect load on the environment and require
infrastructure adjustments. Document relevant changes and their expected timeline.

#### Determine growth buffer strategy

Based on historical trends and business projections, select the appropriate growth accommodation strategy:

- Stable or minimal growth: Continue monitoring. Reference architectures include built-in headroom.
- Moderate growth: Plan for RA sized to handle projected future RPS.
- Significant growth anticipated: Consider sizing for projected future RPS rather than current RPS.

### Before you proceed

Having completed this section, growth projections are incorporated into sizing decision.

Record the complete growth analysis:

```plaintext
Growth Assessment Summary:
- Historical RPS comparison: _____
- Business growth factors: _____
- Growth category: [ ] Stable/Minimal [ ] Moderate [ ] Significant
- Strategy: [ ] Current RA sufficient [ ] Size for projected growth
```

In the next section, you compile all findings into final architecture recommendations.

## Compile findings

Compile findings from all previous sections to determine the optimal reference architecture and required adjustments.

### Determine final architecture

Gather the key outputs from each section to form the sizing decision:

1. Start with the reference architecture identified based on [RPS analysis](#determine-your-baseline-size).
1. Apply any needed component adjustments based on [workload patterns](#identify-component-adjustments) and
   [data characteristics](#assess-special-infrastructure-requirements). Skip this step if no patterns are identified or
   if standard configuration is sufficient.
1. Validate against [current state](#analyze-current-environment-and-validate-recommendations). If current environment
   performs well but exceeds recommendations, document the reasons. If it has performance issues, ensure recommendations
   exceed current specifications.
1. Accommodate [growth in your plan for future capacity](#plan-for-future-capacity). Determine if the current RA is
   sufficient or if sizing for projected growth is needed.

### Document final recommendation

Based on the comprehensive assessment, record the complete architecture recommendation:

```plaintext
Final Architecture Recommendation
==================================

- Selected RA: [Size] based on [Absolute/Sustained] Peak RPS of [value]
- Component adjustments required:
  - [ ] No adjustments needed - standard RA configuration sufficient
  - [ ] Adjustments required:
      - Rails: _____
      - Sidekiq: _____
      - Database: _____
      - Gitaly: _____
      - Network considerations: □ Standard instances □ Network-optimized instances
- Selected RA is aligned with existing environment: [Yes/No/Not applicable]
- Growth accommodation: [Current RA sufficient / Sized up for growth]

Assessment Summary:
├── RPS Analysis
│   ├── Absolute Peak RPS: _____ → Baseline RA: _____
│   └── Sustained Peak RPS: _____ → Sustained RA: _____
├── Workload Type
│   └── Type: [ ] Database-Intensive [ ] Sidekiq-Intensive [ ] None
├── Data Profile
│   ├── Large repos (>2GB): _____ | Monorepos (>10GB): _____
│   └── Network peak: _____ Gbps
├── Current State
│   ├── Nearest RA: _____
|   └── Discrepancies and customizations: _____
└── Growth
    ├── Growth projection: _____
    └── Growth buffer strategy: _____
```

Having completed all the sections, the sizing assessment is complete. The final recommendation includes:

- The base reference architecture size.
- Component-specific adjustments
- Growth accommodation strategy.

Regular monitoring remains essential to validate assumptions and adjust infrastructure as workload patterns evolve.
