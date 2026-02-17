---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runner fleet dashboard for administrators
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/424495) in GitLab 16.6

{{< /history >}}

As a GitLab administrator, you can use the runner fleet dashboard to assess the health of your instance runners.
The runner fleet dashboard shows:

- Recent CI errors caused by runner infrastructure
- Number of concurrent jobs executed on most busy runners
- Compute minutes used by instance runners
- Job queue times

![Runner fleet dashboard displaying status, usage, and performance metrics.](img/runner_fleet_dashboard_v17_1.png)

## Dashboard metrics

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11180) metrics, **Runner usage** and **Wait time to pick up job**, as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab 16.7 with [flags](../../administration/feature_flags/_index.md) named `ci_data_ingestion_to_click_house` and `clickhouse_ci_analytics`. Disabled by default.
- **Runner usage** and **Wait time to pick up job** metrics [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/424789) to [beta](../../policy/development_stages_support.md#beta) in GitLab 17.1.

{{< /history >}}

The following metrics are available in the runner fleet dashboard:

> [!note]
> To view **Runner usage** and **Wait time to pick a job** metrics, you must configure the [ClickHouse integration](../../integration/clickhouse.md).
>
> <i class="fa-youtube-play" aria-hidden="true"></i>
> For an overview, see [setting up runner fleet dashboard with ClickHouse](https://www.youtube.com/watch?v=YpGV95Ctbpk).
> <!-- Video published on 2023-12-19 -->

| Metric                        | Description |
|-------------------------------|-------------|
| Online                        | Number of runners that are online for the entire instance. |
| Offline                       | Number of runners that are currently offline. Runners that were registered but never connected to GitLab are not included in this count. |
| Active runners                | The total number of runners that are currently active. |
| Runner usage (previous month)<sup>1</sup> | **Requires ClickHouse**: The total compute minutes used by each project or group runner in the previous month. You can export this data as a CSV file for cost analysis. |
| Wait time to pick a job<sup>1</sup>       | **Requires ClickHouse**: The average time a job waits in the queue before a runner picks it up. This metric provides insights into whether your runners are capable of servicing the CI/CD job queue in your organization's target service-level objectives (SLOs). This data is updated every 24 hours. |

**Footnotes**:

1. This feature is in [beta](../../policy/development_stages_support.md#beta) and subject to change without notice.
   For more information, see [epic 11180](https://gitlab.com/groups/gitlab-org/-/epics/11180).

## View the runner fleet dashboard

Prerequisites:

- You must be an administrator.
- To view metrics for **Runner usage** and **Wait time to pick a job**, you must configure the [ClickHouse integration](../../integration/clickhouse.md).

To view the runner fleet dashboard:

1. In the upper-right corner, select **Admin**.
1. Select **Runners**.
1. Select **Fleet dashboard**.

## Export compute minutes used by instance runners

Prerequisites:

- You must have administrator access to the instance.
- You must configure the [ClickHouse integration](../../integration/clickhouse.md).

To analyze runner usage, you can export a CSV file that contains the number of jobs and executed runner minutes. The
CSV file shows the runner type and job status for each project. The CSV is sent to your email when the export is completed.

To export compute minutes used by instance runners:

1. In the upper-right corner, select **Admin**.
1. Select **Runners**.
1. Select **Fleet dashboard**.
1. Select **Export CSV**.

## Feedback

To help us improve the runner fleet dashboard, you can provide feedback in
[issue 421737](https://gitlab.com/gitlab-org/gitlab/-/issues/421737).
In particular:

- How easy or difficult it was to set up GitLab to make the dashboard work.
- How useful you found the dashboard.
- What other information you would like to see on that dashboard.
- Any other related thoughts and ideas.
