---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CI/CD analytics **(FREE)**

## Pipeline success and duration charts

> [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/38318) to CI/CD Analytics in GitLab 12.8.

CI/CD analytics shows the history of your pipeline successes and failures, as well as how long each pipeline
ran.

View successful pipelines:

![Successful pipelines](img/pipelines_success_chart.png)

View pipeline duration history:

![Pipeline duration](img/pipelines_duration_chart.png)

Pipeline statistics are gathered by collecting all available pipelines for the
project regardless of status. The data available for each individual day is based
on when the pipeline was created. The total pipeline calculation includes child
pipelines and pipelines that failed with invalid YAML. If you are interested in
filtering pipelines based on other attributes, consider using the [Pipelines API](../../api/pipelines.md#list-project-pipelines).

## View CI/CD analytics

To view CI/CD analytics:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > CI/CD Analytics**.

## DevOps Research and Assessment (DORA) key metrics **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/275991) in GitLab 13.7.
> - [Added support](https://gitlab.com/gitlab-org/gitlab/-/issues/291746) for lead time for changes in GitLab 13.10.

The DevOps Research and Assessment ([DORA](https://cloud.google.com/blog/products/devops-sre/the-2019-accelerate-state-of-devops-elite-performance-productivity-and-scaling))
team developed several key metrics that you can use as performance indicators for software development
teams:

- Deployment frequency: How often an organization successfully releases to production.
- Lead time for changes: The amount of time it takes for code to reach production.
- Change failure rate: The percentage of deployments that cause a failure in production.
- Time to restore service: How long it takes for an organization to recover from a failure in
  production.

### Supported metrics in GitLab

The following table shows the supported metrics, at which level they are supported, and which GitLab version (API and UI) they were introduced:

| Metric                    | Level               | API version                          | Chart (UI) version                    | Comments  |
|---------------------------|---------------------|--------------------------------------|---------------------------------------|-----------|
| `deployment_frequency`    | Project-level       | [13.7+](../../api/dora/metrics.md)   | [13.8+](#view-deployment-frequency-chart) | The [old API endpoint](../../api/dora4_project_analytics.md) was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/323713) in 13.10. |
| `deployment_frequency`    | Group-level         | [13.10+](../../api/dora/metrics.md)  | [13.12+](#view-deployment-frequency-chart)                    | |
| `lead_time_for_changes`   | Project-level       | [13.10+](../../api/dora/metrics.md)  | [13.11+](#view-lead-time-for-changes-chart)           | Unit in seconds. Aggregation method is median. |
| `lead_time_for_changes`   | Group-level         |  [13.10+](../../api/dora/metrics.md) | [14.0+](#view-lead-time-for-changes-chart)               | Unit in seconds. Aggregation method is median. |
| `change_failure_rate`     | Project/Group-level |  To be supported                     | To be supported                       | |
| `time_to_restore_service` | Project/Group-level |  To be supported                     | To be supported                       | |

## View deployment frequency chart **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/275991) in GitLab 13.8.

The deployment frequency charts show information about the deployment
frequency to the `production` environment. The environment must be part of the
[production deployment tier](../../ci/environments/index.md#deployment-tier-of-environments)
for its deployment information to appear on the graphs.

The deployment frequency chart is available for groups and projects.

To view the deployment frequency chart:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > CI/CD Analytics**.
1. Select the **Deployment frequency** tab.

![Deployment frequency](img/deployment_frequency_charts_v13_12.png)

## View lead time for changes chart **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/250329) in GitLab 13.11.

The lead time for changes chart shows information about how long it takes for
merge requests to be deployed to a production environment. This chart is available for groups and projects.

- Small lead times indicate fast, efficient deployment
  processes.
- For time periods in which no merge requests were deployed, the charts render a
  red, dashed line.

To view the lead time for changes chart:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > CI/CD Analytics**.
1. Select the **Lead time** tab.

![Lead time](img/lead_time_chart_v13_11.png)
