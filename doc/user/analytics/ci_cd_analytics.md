---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD analytics
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use CI/CD analytics to gain insights into your pipeline performance and success rates.

The CI/CD analytics page provides visualizations for critical CI/CD pipeline metrics directly in the GitLab UI.
These visualizations can help development teams quickly understand the health and efficiency of their software development process.

## View CI/CD analytics

{{< history >}}

- [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/353607) in GitLab 18.0 to improve analytics by using ClickHouse as the data source when available.

{{< /history >}}

To view CI/CD analytics:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Analyze** > **CI/CD analytics**.

## Pipeline metrics

You can view the history of your pipeline successes and failures, and how long each pipeline ran.
Pipeline statistics are gathered by collecting all available pipelines for the
project, regardless of status. The data available for each individual day is based
on when the pipeline started.

CI/CD analytics displays key metrics about your pipelines:

- **Total pipeline runs**: The total number of pipelines that have run in the selected time period. The total pipeline calculation includes child pipelines and pipelines that failed with an invalid YAML.
  To filter pipelines based on other attributes, use the [Pipelines API](../../api/pipelines.md#list-project-pipelines).
- **Median duration**: The median time it takes for pipelines to complete.
- **Failure rate**: The percentage of pipelines that failed.
- **Success rate**: The percentage of pipelines that completed successfully.
- **Other rate**: The percentage of pipelines that were skipped or canceled.

## Filter your results

You can filter the analytics data to focus on specific areas:

- **Source**: Filter by pipeline trigger source.
- **Branch**: Filter by the branch where the pipeline ran.
- **Date range**: Select the time period to analyze (for example, last week).

Filtering allows you to analyze the performance of specific workflow components or compare different branches.

## Pipeline duration chart

The duration chart shows how your pipeline execution times changed over time. The chart displays:

- **Median (50th percentile)**: The typical pipeline duration.
- **95th percentile**: 95% of pipelines complete in this time or less, while only 5% take longer.

This visualization helps you identify trends in pipeline duration, which can help you determine your CI/CD process efficiency over time.

## Pipeline status chart

The status chart shows the distribution of pipeline statuses over time:

- **Successful**: Pipelines that completed without errors.
- **Failed**: Pipelines that did not complete successfully due to errors.
- **Other**: Pipelines with other statuses (canceled, skipped).

This visualization helps you track the stability of your pipelines and identify periods with higher failure rates.

## CI/CD job performance metrics

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Limited availability

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/18548) in GitLab 18.9 as limited availability.

{{< /history >}}

> [!note]
> Not available by default on GitLab Self-Managed or GitLab Dedicated.
> To view CI/CD job performance metrics on GitLab Self-Managed and GitLab Dedicated instances, you must configure [ClickHouse](../../integration/clickhouse.md).

CI/CD job performance trends enable developers to identify inefficient or problematic CI/CD jobs quickly. By including these capabilities
directly in the GitLab UI, developers have the context to pinpoint and fix CI/CD performance problems

Job performance metrics let you identify bottlenecks, monitor job reliability, and focus optimization efforts on jobs with the highest
impact on overall pipeline duration.

The job performance section displays metrics for each job in your pipelines for the selected time period:

- **Job name**: Name of the CI/CD job.
- **P50 duration** (median): Typical execution time for this job. Half of job runs complete faster, half take longer.
- **P95 duration**: 95% of job runs complete within this time. Use this metric to identify outliers and worst-case scenarios.
- **Failure rate**: Percentage of job runs that failed. Higher rates indicate reliability issues and require investigation.

By default, the table sorts by mean duration (longest running jobs first). The table shows 10 jobs per page with pagination controls.
You can select any column header to sort by that metric, or use the search bar to find specific jobs by name.
