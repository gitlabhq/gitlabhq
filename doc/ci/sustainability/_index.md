---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Measure, analyze, and reduce the carbon emissions from your pipelines and infrastructure.
title: CI/CD sustainability
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> The sustainability tools described on this page are third-party integrations.
> GitLab does not maintain or provide support for these tools,
> and makes no representation that these tools satisfy any regulatory or compliance requirements.

You can integrate third-party tools to measure, analyze, and reduce the carbon emissions
from your pipelines and infrastructure.

The right tool depends on what you want to measure:

- To measure emissions from CI/CD pipeline jobs, use [Eco CI](eco_ci.md).
- To measure emissions from virtual machines, pods, or application workloads, use [Carmen](carmen.md).

## Eco CI

Eco CI measures energy consumption and carbon emissions of CI/CD pipelines.
It runs as lightweight bash scripts in your pipeline jobs and does not require
separate servers or databases.

Use Eco CI to:

- Measure the energy consumption and carbon emissions of CI/CD pipeline jobs.
- Identify resource-intensive jobs in your pipeline.
- Track carbon emissions per pipeline run over time.
- Display a carbon emissions badge in your project README.

## Carmen

Carmen (Carbon Measurement Engine) is an open source tool that measures carbon emissions from
virtual machines, pods, and application workloads. It is built on the
[Green Software Foundation Impact Framework](https://if.greensoftware.foundation/).

Use Carmen to:

- Identify which services, VMs, or pods in your stack emit the most CO2.
- Compare components and prioritize reductions.
- Feed per-component carbon scores into your own FinOps dashboards or internal tooling.

Do not use Carmen for:

- Corporate or ESG reporting.
- Press releases or marketing material.
- Compliance or regulatory disclosures.

## Best practices

The following strategies can help reduce the carbon emissions of your CI/CD workflows.

### Optimize job execution

To optimize job execution:

- Use caching to avoid redundant work.
- Run resource-intensive builds once in an early job, then share the output as an artifact
  with later jobs that need it.
- Set appropriate timeout values to prevent runaway jobs.
- Use smaller Docker images to reduce download and startup time.

### Choose efficient runners

To choose efficient runners:

- Select runner instance types that match your workload requirements.
- Avoid over-provisioning resources for small jobs.
- Use spot instances for non-critical workloads.
- Use autoscaling to match capacity with demand.

### Schedule strategically

To schedule strategically:

- Schedule resource-intensive pipelines to run when most renewable energy is available
  in your CI server's region. Check [Electricity Maps](https://app.electricitymaps.com/map/live/hourly)
  to find the best times and regions.
  Midday is usually a good default choice.
- Consider carbon-aware scheduling for non-urgent pipelines.
- Batch similar jobs together to improve resource utilization.

### Monitor and iterate

To monitor and iterate on your sustainability efforts:

- Establish baseline metrics for your pipelines.
- Set targets for emission reduction.
- Review high-impact jobs regularly for optimization opportunities.
- Share sustainability metrics with your team.

## Related topics

- [Pipeline efficiency](../pipelines/pipeline_efficiency.md)
- [Caching dependencies](../caching/_index.md)
- [Scheduled pipelines](../pipelines/schedules.md)
