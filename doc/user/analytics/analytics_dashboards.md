---
stage: Monitor
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Analytics dashboards

DETAILS:
**Tier:** Ultimate
**Offering:** Self-managed
**Status:** Experiment

> - Introduced in GitLab 15.9 as an [Experiment](../../policy/experiment-beta-support.md#experiment) feature [with a flag](../../administration/feature_flags.md) named `combined_analytics_dashboards`. Disabled by default.
> - `combined_analytics_dashboards` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/389067) by default in GitLab 16.11.

Analytics dashboards help you visualize the collected data.
You can use built-in dashboards or create your own with custom visualizations.

## Data sources

A data source is a connection to a database or collection of data which can be used by your dashboard
filters and visualizations to query and retrieve results.

The following data sources are configured for analytics dashboards:

- [Product analytics](../product_analytics/index.md)
- [Value Stream Management](../analytics/value_streams_dashboard.md)

To contribute, see [adding a new visualization data source](../../development/fe_guide/customizable_dashboards.md#adding-a-new-visualization-data-source).

## Built-in dashboards

To help you get started with analytics, GitLab provides built-in dashboards with predefined visualizations.
These dashboards are labeled **By GitLab**, and you cannot edit them.
Instead, you can create a custom dashboard with a similar style.

### Product analytics

When [product analytics](../product_analytics/index.md) is enabled and onboarded, two built-in dashboard are added:

- **Audience** displays metrics related to traffic, such as the number of users and sessions.
- **Behavior** displays metrics related to user activity, such as the number of page views and events.

For more information about the development of product analytics, see the [group direction page](https://about.gitlab.com/direction/monitor/product-analytics/). To leave feedback about bugs or functionality:

- Comment on issue [391970](https://gitlab.com/gitlab-org/gitlab/-/issues/391970).
- Create an issue with the `group::product analytics` label.

### Value Stream Management

- **Value Streams Dashboard** displays metrics related to [DevOps performance, security exposure, and workstream optimization](../analytics/value_streams_dashboard.md#devsecops-metrics-comparison-panel).

## Custom dashboards

With custom dashboards, you can design and create visualizations for the metrics that are most relevant to your use case.
You can create custom dashboards with the dashboard designer.

- Each project can have an unlimited number of dashboards.
  The only limitation might be the [repository size limit](../project/repository/reducing_the_repo_size_using_git.md#storage-limits).
- Each dashboard can reference one or more [visualizations](#define-a-chart-visualization).
- Visualizations are shared across dashboards.

Project maintainers can enforce approval rules on dashboard changes with features such as [code owners](../project/codeowners/index.md) and [approval rules](../project/merge_requests/approvals/rules.md).
Your dashboard files are versioned in source control with the rest of a project's code.

## Dashboard designer

> - Introduced in GitLab 16.1 [with a flag](../../administration/feature_flags.md) named `combined_analytics_dashboards_editor`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/411407) in GitLab 16.6. Feature flag `combined_analytics_dashboards_editor` removed.

You can use the dashboard designer to:

- [Create custom dashboards](#create-a-custom-dashboard).
- [Edit custom dashboards](#edit-a-custom-dashboard) to:
  - Rename the dashboard.
  - Add and remove visualizations.
  - Resize or move panels.

## Visualization designer

> - Introduced in GitLab 16.4 [with a flag](../../administration/feature_flags.md) named `combined_analytics_visualization_editor`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/425048) in GitLab 16.7. Feature flag `combined_analytics_visualization_editor` removed.

NOTE:
This feature is only compatible with the [product analytics](../product_analytics/index.md) data source.

You can use the dashboard designer to:

- [Create custom visualizations](#create-a-custom-visualization).
- Explore available data.

## View project dashboards

Prerequisites:

- You must have at least the Developer role for the project.

To view a list of dashboards (both built-in and custom) for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. From the list of available dashboards, select the dashboard you want to view.

### View the value streams dashboard

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137483) in GitLab 16.7 [with a flag](../../administration/feature_flags.md) named `project_analytics_dashboard_dynamic_vsd`. Disabled by default.

Prerequisites:

- You must have at least the Reporter role for the project.
- Overview background aggregation for Value Streams Dashboards must be enabled.

To view the Value Streams Dashboard as an analytics dashboard for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. From the list of available dashboards, select **Value Streams Dashboard**.

## View group dashboards

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390542) in GitLab 16.2 [with a flag](../../administration/feature_flags.md) named `group_analytics_dashboards`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/416970) in GitLab 16.8.
> - Feature flag `group_analytics_dashboards` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/439718) in GitLab 16.11.

Prerequisites:

- You must have at least the Reporter role for the group.

To view a list of dashboards (both built-in and custom) for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Analytics dashboards**.
1. From the list of available dashboards, select the dashboard you want to view.

### View the value streams dashboard

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132839) in GitLab 16.6 [with a flag](../../administration/feature_flags.md) named `group_analytics_dashboard_dynamic_vsd`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per group or for your entire instance, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `group_analytics_dashboard_dynamic_vsd`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

To view the Value Streams Dashboard as an analytics dashboard for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Analytics dashboards**.
1. From the list of available dashboards, select **Value Streams Dashboard**.

## Change the location of dashboards

You can change the location of your project or group dashboards.

Prerequisites:

- You must have at least the Maintainer role for the project or group the project belongs to.

### Group dashboards

NOTE:
This feature will be connected to group-level dashboards as part of [issue #411572](https://gitlab.com/gitlab-org/gitlab/-/issues/411572).

To change the location of a group's dashboards:

1. On the left sidebar, select **Search or go to** and find the project you want to store your dashboard files in.
   The project must belong to the group for which you create the dashboards.
1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Analytics**.
1. In the **Analytics Dashboards** section, select your dashboard files project.
1. Select **Save changes**.

### Project dashboards

Dashboards are usually defined in the project where the analytics data is being retrieved from.
However, you can also have a separate project for dashboards.
This is recommended if you want to enforce specific access rules to the dashboard definitions or share dashboards across multiple projects.

NOTE:
You can share dashboards only between projects that are located in the same group.

To change the location of project dashboards:

1. On the left sidebar, select **Search or go to** and find your project,
   or select **Create new** (**{plus}**) and **New project/repository**
   to create the project to store your dashboard files.
1. On the left sidebar, select **Search or go to** and find the analytics project.
1. Select **Settings > General**.
1. Expand **Analytics**.
1. In the **Analytics Dashboards** section, select your dashboard files project.
1. Select **Save changes**.

## Define a dashboard

To define a dashboard:

1. In `.gitlab/analytics/dashboards/`, create a directory named like the dashboard.

   Each dashboard should have its own directory.
1. In the new directory, create a `.yaml` file with the same name as the directory, for example `.gitlab/analytics/dashboards/my_dashboard/my_dashboard.yaml`.

   This file contains the dashboard definition. It must conform to the JSON schema defined in `ee/app/validators/json_schemas/analytics_dashboard.json`.
1. Optional. To create new visualizations to add to your dashboard see [defining a chart visualization](#define-a-chart-visualization).

For [example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/product_analytics/dashboards/audience.yaml), if you want to create three dashboards (Conversion funnels, Demographic breakdown, and North star metrics)
and one visualization (line chart) that applies to all dashboards, the file structure would be:

```plaintext
.gitlab/analytics/dashboards
├── conversion_funnels
│  └── conversion_funnels.yaml
├── demographic_breakdown
│  └── demographic_breakdown.yaml
├── north_star_metrics
|  └── north_star_metrics.yaml
├── visualizations
│  └── example_line_chart.yaml
```

## Define a chart visualization

You can define different charts, and add visualization options to some of them:

- Line chart, with the options listed in the [ECharts documentation](https://echarts.apache.org/en/option.html).
- Column chart, with the options listed in the [ECharts documentation](https://echarts.apache.org/en/option.html).
- Data table.
- Single stat, with the only option to set `decimalPlaces` (number, default value is 0).

To define a chart for your dashboards:

1. In the `.gitlab/analytics/dashboards/visualizations/` directory, create a `.yaml` file.
   The filename should be descriptive of the visualization it defines.
1. In the `.yaml` file, define the visualization configuration, according to the schema in
   `ee/app/validators/json_schemas/analytics_visualization.json`.

For [example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/product_analytics/visualizations/events_over_time.yaml), to create a line chart that illustrates event count over time, in the `visualizations` folder
create a `line_chart.yaml` file with the following required fields:

- version
- type
- data
- options

To contribute, see [adding a new visualization render type](../../development/fe_guide/customizable_dashboards.md#adding-a-new-visualization-render-type).

## Create a custom dashboard

To create a custom dashboard:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. Select **New dashboard**.
1. In the **New dashboard** input, enter the name of the dashboard.
1. From the **Add visualizations** list on the right, select the visualizations to add to the dashboard.
1. Optional. Drag or resize the selected panel how you prefer.
1. Select **Save**.

## Edit a custom dashboard

You can edit your custom dashboard's title and add or resize visualizations in the dashboard designer.

To edit an existing custom dashboard:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. From the list of available dashboards, select a custom dashboard (one without the `By GitLab` label) you want to edit.
1. Select **Edit**.
1. Optional. Change the title of the dashboard.
1. Optional. From the **Add visualizations** list on the right, select other visualizations to add to the dashboard.
1. Optional. In the dashboard, select a panel and drag or resize it how you prefer.
1. Select **Save**.

## Create a custom visualization

To create a custom visualization:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. Select **Visualization designer**.
1. In the **Visualization title** field, enter the name of your visualization.
1. From the **Visualization type** dropdown list, select a visualization type.
1. In the **What metric do you want to visualize?** section, select the metric you want to query.
1. Optional. To refine your query, select a dimension.
1. Select **Save**.

After you saved a visualization, you can add it to a new or existing custom dashboard in the same project.

## Troubleshooting

### `Something went wrong while loading the dashboard.`

If the dashboard displays a global error message that data could not be loaded, first try reloading the page. If the error persists:

- Check that your configurations match the [dashboard JSON schema](#define-a-dashboard) defined in `ee/app/validators/json_schemas/analytics_dashboard.json`.
- For product analytics, check your [admin and project settings](../product_analytics/index.md#project-level-settings), and make sure they are set up correctly.

### `Invalid visualization configuration`

If a dashboard panel displays a message that the visualization configuration is invalid, check that your visualization configurations match the [visualization JSON schema](#define-a-chart-visualization) defined in `ee/app/validators/json_schemas/analytics_visualization.json`.

### Dashboard panel error

If a dashboard panel displays an error message:

- Check your [Cube query](../product_analytics/index.md#product-analytics-dashboards) and [visualization](../analytics/analytics_dashboards.md#define-a-chart-visualization)
  configurations, and make sure they are set up correctly.
- For [product analytics](../product_analytics/index.md), also check that your visualization's Cube query is valid.
