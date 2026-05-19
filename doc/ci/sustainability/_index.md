---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Measure and reduce the carbon footprint of your CI/CD pipelines with sustainability tools.
title: Pipeline sustainability
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> The sustainability tools described on this page are third-party integrations.
> GitLab does not maintain or provide support for these tools,
> and makes no representation that these tools satisfy any regulatory or compliance requirements.

CI/CD pipelines consume computational resources that generate carbon emissions.
You can integrate third-party tools to measure and reduce Scope 3 emissions from your software development
workflows for sustainability reporting and regulatory compliance.

Scope 3 emissions are indirect emissions from your supply chain and vendors,
including the cloud infrastructure that runs your CI/CD pipelines.

Integrating sustainability tools into your pipelines provides these benefits:

- Track and report carbon emissions from your CI/CD infrastructure.
- Identify resource-intensive jobs and optimization opportunities.
- Make data-driven decisions about runner selection and job scheduling.
- Meet sustainability goals and regulatory requirements.

## Emission measurement

CI/CD pipeline emissions come from the computational resources used to execute jobs.
The carbon footprint depends on energy consumption from CPU utilization,
memory usage, and execution time. It also varies based on carbon intensity,
which represents the carbon emissions per unit of electricity and changes by region and time of day.
Infrastructure factors like cloud providers, data center locations,
and hardware efficiency also contribute to the overall impact.

Sustainability tools use different approaches to calculate emissions:

- Estimation models calculate energy consumption based on CPU usage patterns and
  pre-calculated power curves.
- Actual measurement uses cloud provider APIs to retrieve real resource consumption data.
- Carbon intensity lookups query services like [Electricity Maps](https://app.electricitymaps.com/dashboard)
  to apply regional carbon factors and time-based variations.

## Measure emissions with Eco CI

Eco CI measures energy consumption and carbon emissions of CI/CD pipelines.
It runs as lightweight bash scripts within your pipeline jobs and does not require
separate servers or databases.

For more information, see [Eco CI](eco_ci.md).

## Best practices

Consider the following strategies to reduce the carbon footprint of your CI/CD pipelines.

### Optimize job execution

To optimize job execution:

- Use caching to avoid redundant work.
- Instead of doing resource intensive builds at the start of multiple jobs, run the build once in an early job.
  Then share the output as an artifact with all later jobs that need it.
- Set appropriate timeout values to prevent runaway jobs.
- Use smaller Docker images to reduce download and startup time.

### Choose efficient runners

To choose efficient runners:

- Select runner instance types that match your workload requirements.
- Avoid over-provisioning resources for simple jobs.
- Consider using spot instances for non-critical workloads.
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
