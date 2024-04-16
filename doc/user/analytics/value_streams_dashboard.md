---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Value Streams Dashboard

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Introduced in GitLab 15.8 as a Closed [Beta](../../policy/experiment-beta-support.md#beta) feature [with a flag](../../administration/feature_flags.md) named `group_analytics_dashboards_page`. Disabled by default.
> - Released in GitLab 15.11 as an Open [Beta](../../policy/experiment-beta-support.md#beta) feature [with a flag](../../administration/feature_flags.md) named `group_analytics_dashboards_page`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/392734) in GitLab 16.0. Feature flag `group_analytics_dashboards_page` removed.

To help us improve the Value Streams Dashboard, share feedback about your experience in this [survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4).
For more information, see also the [Value Stream Management category direction page](https://about.gitlab.com/direction/plan/value_stream_management/).

The Value Streams Dashboard is a customizable dashboard you can use to identify trends, patterns, and opportunities for digital transformation improvements.
The centralized UI in Value Streams Dashboard acts as the single source of truth (SSOT), where all stakeholders can access and view the same set of metrics that are relevant to the organization.

The Value Streams Dashboard includes two panels (DevSecOps metrics comparison and DORA Performers score) that visualize the following metrics:

- [DORA metrics](dora_metrics.md)
- [Value Stream Analytics (VSA) - flow metrics](../group/value_stream_analytics/index.md)
- [Vulnerabilities](https://gitlab.com/gitlab-org/gitlab/-/security/vulnerability_report) metrics.

With the Value Streams Dashboard, you can:

- Track and compare the above metrics over a period of time.
- Identify downward trends early on.
- Understand security exposure.
- Drill down into individual projects or metrics to take actions for improvement.

NOTE:
Data displayed on the Value Streams Dashboard is continuously collected in the backend.
If you upgrade to the Ultimate tier, you get access to historical data, and can view metrics about past GitLab usage and performance.

## Value Streams Dashboard panels

The Value Streams Dashboard panels has a default configuration, but you can also [customize the dashboard panels](#customize-the-dashboard-panels).

### Overview panel

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/439699) in GitLab 16.7 [with a flag](../../administration/feature_flags.md) named `group_analytics_dashboard_dynamic_vsd`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per group or for your entire instance, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `group_analytics_dashboard_dynamic_vsd`. On GitLab.com, this feature is available.

The Overview panel provides a holistic view of the top-level namespace activity by visualizing key DevOps metrics.
The panel displays metrics for:

- Subgroups
- Projects
- Users
- Issues
- Merge requests
- Pipelines

Data displayed in the Overview panel is collected by batch processing. GitLab stores record counts for each subgroup in the database, then aggregates the record counts to provide metrics for the top-level group.
Data is aggregated monthly, around the end of the month, on a best-effort basis depending on the load on GitLab systems.

For more information, see [epic 10417](https://gitlab.com/groups/gitlab-org/-/epics/10417#iterations-path).

NOTE:
To view metrics on the Overview panel, the [background aggregation](#enable-or-disable-overview-background-aggregation) must be enabled.

### DevSecOps metrics comparison panel

> - Contributor count metric [added](https://gitlab.com/gitlab-org/gitlab/-/issues/433353) in GitLab 16.9.

The DevSecOps metrics comparison displays DORA4, vulnerability, and flow metrics for a group or project in the
month-to-date, last month, the month before, and the past 180 days.

This visualization helps you get a high-level custom view over multiple DevOps metrics and
understand whether they're improving month over month. You can compare the performance between
groups, projects, and teams at a glance. This visualization helps you identify the teams and projects
that are the largest value contributors, overperforming, or underperforming.

![DevOps metrics comparison](img/devops_metrics_comparison_v15_8.png)

You can also drill down the metrics for further analysis.
When you hover over a metric, a tooltip displays an explanation of the metric and a link to the related documentation page.

The monthly values also indicate a percentage increase or decrease compared to the previous month.

The sparkline for the past six months represents value trends over this time period, not the percentage change rate.
The sparkline color ranges from blue to green, where green indicates a positive trend, and blue indicates a negative trend.
Sparklines help you identify patterns in metric trends (such as seasonal changes) over time.

NOTE:
The contributor count metric is available only on GitLab.com at the group-level. To view this metric in the comparison panel, you must [set up ClickHouse](../../integration/clickhouse.md).

### DORA Performers score panel

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386843) in GitLab 16.3 [with a flag](../../administration/feature_flags.md) named `dora_performers_score_panel`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/439737) in GitLab 16.9.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/440694) in GitLab 16.11. Feature flag `dora_performers_score_panel` removed.

The [DORA metrics](dora_metrics.md) Performers score panel is a bar chart that visualizes the status of the organization's DevOps performance levels across different projects.

The chart is a breakdown of your project's DORA scores, categorized as high, medium, or low.
It aggregates all the child projects in the group.

Each bar on the chart displays the sum of total projects per score category, calculated monthly.
To exclude data from the chart (for example, "Not Included"), in the legend select the series you want to exclude.
Hovering over each bar reveals a dialog that explains the score's definition.

For example, if a project has a high score for deployment frequency (velocity), it means that the project has one or more deploys to production per day.

| Metric | Description | High | Medium | Low |
|--------|-------------|------|--------|-----|
| Deployment frequency  | The number of deploys to production per day | ≥30 | 1-29 | \<1 |
| Lead time for changes | The number of days to go from code committed to code successfully running in production| ≤7 | 8-29 | ≥30 |
| Time to restore service | The number of days to restore service when a service incident or a defect that impacts users occurs | ≤1 | 2-6 | ≥7 |
| Change failure rate  | The percentage of changes to production resulted in degraded service | ≤15% | 16%-44% | ≥45% |

These scoring are based on Google's classifications in the [DORA 2022 Accelerate State of DevOps Report](https://cloud.google.com/blog/products/devops-sre/dora-2022-accelerate-state-of-devops-report-now-out).

#### Filter the DORA Performers score by project topics

When used in combination with a [YAML configuration](#using-yaml-configuration), you can filter the projects shown based on their assigned [topics](../project/project_topics.md).

```yaml
panels:
  - data:
      namespace: group/my-custom-group
      filter_project_topics:
        - JavaScript
        - Vue.js
```

If multiple topics are provided, all topics will need to match for the project to be included in the results.

## Enable or disable overview background aggregation

DETAILS:
**Tier:** Ultimate
**Offering:** Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120610) in GitLab 16.1 [with a flag](../../administration/feature_flags.md) named `value_stream_dashboard_on_off_setting`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130704) in GitLab 16.4.
> - [Feature flag `value_stream_dashboard_on_off_setting` removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134619) in GitLab 16.6.

To enable or disable the overview count aggregation for the Value Streams Dashboard:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Analytics**.
1. In **Value Streams Dashboard**, select or clear the **Enable overview background aggregation for Value Streams Dashboard** checkbox.

To retrieve aggregated usage counts in the group, use the [GraphQL API](../../api/graphql/reference/index.md#groupvaluestreamdashboardusageoverview).

## View the value streams dashboard

Prerequisites:

- You must have at least the Reporter role for the group.
- Overview background aggregation for Value Streams Dashboards must be enabled.

To view the value streams dashboard:

- From Analytics Dashboards:

   1. On the group left sidebar, select **Search or go to** and find your group.
   1. Select **Analyze > Analytics Dashboards**.

- From Value Stream Analytics:

   1. On the left sidebar, select **Search or go to** and find your project or group.
   1. Select **Analyze > Value stream analytics**.
   1. Below the **Filter results** text box, in the **Lifecycle metrics** row, select **Value Streams Dashboard / DORA**.
   1. Optional. To open the new page, append this path `/analytics/dashboards/value_streams_dashboard` to the group URL (for example, `https://gitlab.com/groups/gitlab-org/-/analytics/dashboards/value_streams_dashboard`).

You can also view the Value Streams Dashboard rendered as an analytics dashboard for a [group](analytics_dashboards.md#view-group-dashboards) or [project](analytics_dashboards.md#view-project-dashboards).

## Customize the dashboard panels

You can customize the Value Streams Dashboard and configure what subgroups and projects to include in the page.

### Using query parameters

To display multiple subgroups and projects, specify their path as a URL parameter.

For example, the parameter `query=gitlab-org/gitlab-ui,gitlab-org/plan-stage` displays three separate panels, one each for the:

- `gitlab-org` group
- `gitlab-ui` project
- `gitlab-org/plan-stage` subgroup

### Using YAML configuration

> - Schema for group Analytics Dashboards [changed](#schema-for-group-analytics-dashboards) in GitLab 16.10.

To customize the default content of the page, you need to create a YAML configuration file in a project of your choice. In this file you can define various settings and parameters, such as title, description, and number of panels and labels filters. The file is schema-driven and managed with version control systems like Git. This enables tracking and maintaining a history of configuration changes, reverting to previous versions if necessary, and collaborating effectively with team members.
Query parameters can still be used to override the YAML configuration.

First, you need to set up the project.

Prerequisites:

- You must have at least the Maintainer role for the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Analytics**.
1. Select the project where you would like to store your YAML configuration file.
1. Select **Save changes**.

After you have set up the project, set up the configuration file:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the default branch, create the configuration file: `.gitlab/analytics/dashboards/value_streams/value_streams.yaml`.
1. In the `value_streams.yaml` configuration file, fill in the configuration options:

```yaml
# title - Change the title of the Value Streams Dashboard.
title: 'Custom Dashboard title'

# description - Change the description of the Value Streams Dashboard. [optional]
description: 'Custom description'

# panels - List of panels that contain panel settings.
#   title - Change the title of the panel. [optional]
#   data.namespace - The Group or Project path to use for the chart panel.
#   data.exclude_metrics - Hide rows by metric ID from the chart panel.
#   data.filter_labels -
#     Only show results for data that matches the queried label(s). If multiple labels are provided,
#     only a single label needs to match for the data to be included in the results.
#     Compatible metrics (other metrics will be automatically excluded):
#       * lead_time
#       * cycle_time
#       * issues
#       * issues_completed
#       * merge_request_throughput
panels:
  - title: 'My Custom Project'
    data:
      namespace: group/my-custom-project
  - data:
      namespace: group/another-project
      filter_labels:
        - in_development
        - in_review
  - title: 'My Custom Group'
    data:
      namespace: group/my-custom-group
      exclude_metrics:
        - deployment_frequency
        - change_failure_rate
  - data:
      namespace: group/another-group
```

  The following example has an option configuration for a panel for the `my-group` namespace:

  ```yaml
  panels:
    - data:
        namespace: my-group
  ```

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of editing label filters in the configuration file, see [GitLab Value Streams Dashboard - Label filters demo](https://www.youtube.com/watch?v=4qDAHCxCfik).

#### Schema for group Analytics Dashboards

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per group or for your entire instance, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `group_analytics_dashboard_dynamic_vsd`.
On GitLab.com, this feature is not available.

To render a [Value Streams Dashboard as a custom Analytics Dashboard](analytics_dashboards.md#view-group-dashboards), you must update new and existing [YAML schemas](analytics_dashboards.md). The updated fields provide more flexibility in the display and layout of the dashboard panels.

|Field|Description|
|---|---|
| `title` | Custom name for the panel |
|`queryOverrides` (formerly `data`) | Overrides data query parameters specific to each visualization. |
|`namespace` (subfield of `queryOverrides`) | Group or project path to use for the panel |
|`filters` (subfield of `queryOverrides`) | Filters the query for each visualization type. See [supported visualizations](#supported-visualization-filters). |
| `visualization` | The type of visualization to be rendered. Supported options are `dora_chart`, `dora_performers_score`, and `usage_overview`. |
| `gridAttributes` | The size and positioning of the panel |
| `xPos` (subfield of `gridAttributes`) | Horizontal position of the panel |
| `yPos` (subfield of `gridAttributes`) | Vertical position of the panel |
| `width` (subfield of `gridAttributes`) | Width of the panel (max. 12) |
| `height` (subfield of `gridAttributes`) | Height of the panel |

```yaml
# title - Change the title of the Value Streams Dashboard. [optional]
title: 'Custom Dashboard title'

# description - Change the description of the Value Streams Dashboard. [optional]
description: 'Custom description'

# panels - List of panels that contain panel settings.
#   title - Change the title of the panel.
#   queryOverrides.namespace - The Group or Project path to use for the chart panel
#   queryOverrides.filters.excludeMetrics - Hide rows by metric ID from the chart panel.
#   queryOverrides.filters.labels -
#     Only show results for data that matches the queried label(s). If multiple labels are provided,
#     only a single label needs to match for the data to be included in the results.
#     Compatible metrics (other metrics will be automatically excluded):
#       * lead_time
#       * cycle_time
#       * issues
#       * issues_completed
#       * merge_request_throughput
panels:
  - title: 'Group usage overview'
    visualization: usage_overview
    queryOverrides:
      namespace: group
      filters:
        include:
          - groups
          - projects
    gridAttributes:
      yPos: 1
      xPos: 1
      height: 1
      width: 12
  - title: 'Group dora and issue metrics'
    visualization: dora_chart
    queryOverrides:
      namespace: group
      filters:
        excludeMetrics:
          - deployment_frequency
          - deploys
        labels:
          - in_development
          - in_review
    gridAttributes:
      yPos: 2
      xPos: 1
      height: 12
      width: 12
  - title: 'My dora performers scores'
    visualization: dora_performers_score
    queryOverrides:
      namespace: group/my-project
      filters:
        projectTopics:
          - ruby
          - javasript
    gridAttributes:
      yPos: 26
      xPos: 1
      height: 12
      width: 12
```

#### Supported visualization filters

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per group or for your entire instance, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `group_analytics_dashboard_dynamic_vsd`.
On GitLab.com and GitLab Dedicated, this feature is not available.

The `filters` subfield on the `queryOverrides` field can be used to customize the data displayed in a panel.

##### DevSecOps metrics comparison panel filters

Filters for the `dora_chart` visualization.

|Filter|Description|Supported values|
|---|---|---|
|`excludeMetrics`| Hides rows by metric ID from the chart panel | `deployment_frequency`, `lead_time_for_changes`,`time_to_restore_service`, `change_failure_rate`, `lead_time`, `cycle_time`, `issues`, `issues_completed`, `deploys`, `merge_request_throughput`, `contributor_count`, `vulnerability_critical`, `vulnerability_high`|
| `labels` | Filters data by labels | Any available group label |

##### DORA Performers score panel filters

Filters for the `dora_performers_score` visualization.

|Filter|Description|Supported values|
|---|---|---|
|`projectTopics`|Filters the projects shown based on their assigned [topics](../project/project_topics.md)| Any available group topic|

##### Usage overview panel filters

Filters for the `usage_overview` visualization.

|Filter|Description|Supported values|
|---|---|---|
|`include`|Limits the metrics returned, by default displays all available| `groups`, `projects`, `issues`, `merge_requests`, `pipelines`, `users`|

### Filter the DevSecOps metrics comparison panel by labels

Label filters are appended as query parameters to the URL of the drill-down report of each eligible metric and automatically applied.
If the comparison panel from the configuration file is enabled with `filter_labels`, the drill-down links inherit the labels from the panel filter.

```yaml
  - data:
      namespace: group/another-project
      filter_labels:
        - in_development
        - in_review
```

## Dashboard metrics and drill-down reports

| Metric | Description | Drill-down report | Documentation page | ID |
| ------ | ----------- | --------------- | ------------------ | -- |
| Deployment frequency | Average number of deployments to production per day. This metric measures how often value is delivered to end users. | [Deployment frequency tab](https://gitlab.com/groups/gitlab-org/-/analytics/ci_cd?tab=deployment-frequency) | [Deployment frequency](dora_metrics.md#deployment-frequency) | `deployment_frequency` |
| Lead time for changes | The time to successfully deliver a commit into production. This metric reflects the efficiency of CI/CD pipelines. | [Lead time tab](https://gitlab.com/groups/gitlab-org/-/analytics/ci_cd?tab=lead-time) | [Lead time for changes](dora_metrics.md#lead-time-for-changes) | `lead_time_for_changes` |
| Time to restore service | The time it takes an organization to recover from a failure in production. | [Time to restore service tab](https://gitlab.com/groups/gitlab-org/-/analytics/ci_cd?tab=time-to-restore-service) | [Time to restore service](dora_metrics.md#time-to-restore-service) | `time_to_restore_service` |
| Change failure rate | Percentage of deployments that cause an incident in production. | [Change failure rate tab](https://gitlab.com/groups/gitlab-org/-/analytics/ci_cd?tab=change-failure-rate) | [Change failure rate](dora_metrics.md#change-failure-rate) | `change_failure_rate` |
| Lead time | Median time from issue created to issue closed. | [Value Stream Analytics](https://gitlab.com/groups/gitlab-org/-/analytics/value_stream_analytics) | [View the lead time and cycle time for issues](../group/value_stream_analytics/index.md#lifecycle-metrics) | `lead_time` |
| Cycle time | Median time from the earliest commit of a linked issue's merge request to when that issue is closed. | [VSA overview](https://gitlab.com/groups/gitlab-org/-/analytics/value_stream_analytics) | [View the lead time and cycle time for issues](../group/value_stream_analytics/index.md#lifecycle-metrics) | `cycle_time` |
| Issues created | Number of new issues created. | [Issue Analytics](https://gitlab.com/groups/gitlab-org/-/issues_analytics) | [Issue Analytics](../../user/group/issues_analytics/index.md) | `issues` |
| Issues closed | Number of issues closed by month. | [Issue Analytics](https://gitlab.com/groups/gitlab-org/-/issues_analytics) | [Issue Analytics](../../user/group/issues_analytics/index.md) | `issues_completed` |
| Number of deploys | Total number of deploys to production. | [Merge Request Analytics](https://gitlab.com/gitlab-org/gitlab/-/analytics/merge_request_analytics) | [Merge request analytics](merge_request_analytics.md) | `deploys` |
| Merge request throughput | The number of merge requests merged by month. | [Groups Productivity analytics](productivity_analytics.md), [Projects Merge Request Analytics](https://gitlab.com/gitlab-org/gitlab/-/analytics/merge_request_analytics)  | [Groups Productivity analytics](productivity_analytics.md) [Projects Merge request analytics](merge_request_analytics.md) | `merge_request_throughput` |
| Contributor count | Number of monthly unique users with contributions in the group.| [Contribution Analytics](https://gitlab.com/groups/gitlab-org/-/contribution_analytics) | [User contribution events](../profile/contributions_calendar.md#user-contribution-events) | `contributor_count` |
| Critical vulnerabilities over time | Critical vulnerabilities over time in project or group | [Vulnerability report](https://gitlab.com/gitlab-org/gitlab/-/security/vulnerability_report) | [Vulnerability report](../application_security/vulnerability_report/index.md) | `vulnerability_critical` |
| High vulnerabilities over time | High vulnerabilities over time in project or group | [Vulnerability report](https://gitlab.com/gitlab-org/gitlab/-/security/vulnerability_report) | [Vulnerability report](../application_security/vulnerability_report/index.md) | `vulnerability_high` |

## Value Streams Dashboard metrics with Jira

The following metrics do not depend on using Jira:

- DORA Deployment frequency
- DORA Lead time for changes
- Number of deploys
- Merge request throughput
- Vulnerabilities
