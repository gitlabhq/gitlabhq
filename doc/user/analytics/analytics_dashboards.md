---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Analytics dashboards
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - Introduced in GitLab 15.9 as an [experiment](../../policy/development_stages_support.md#experiment) feature [with a flag](../../administration/feature_flags.md) named `combined_analytics_dashboards`. Disabled by default.
> - `combined_analytics_dashboards` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/389067) by default in GitLab 16.11.
> - `combined_analytics_dashboards` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/454350) in GitLab 17.1.
> - `filters` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/505317) in GitLab 17.9. Disabled by default.
> - Inline visualizations configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/509111) in GitLab 17.9.

Analytics dashboards help you visualize the collected data.
You can use built-in dashboards by GitLab or create your own dashboards with custom visualizations.

## Data sources

> - Product analytics and custom visualization data sources [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/497577) in GitLab 17.7.

A data source is a connection to a database or collection of data which can be used by your dashboard
filters and visualizations to query and retrieve results.

## Built-in dashboards

To help you get started with analytics, GitLab provides built-in dashboards with predefined visualizations.
These dashboards are labeled **By GitLab**.
You cannot edit the built-in dashboards, but you can create custom dashboards with a similar style.

The following built-in dashboards are available:

- [**Value Streams Dashboard**](../analytics/value_streams_dashboard.md) displays metrics related to DevOps performance, security exposure, and workstream optimization.
- [**AI Impact Dashboard**](../analytics/ai_impact_analytics.md) displays the impact of AI tools on software development lifecycle (SDLC) metrics for a project or group.

## Custom dashboards

Use custom dashboards to design and create visualizations for the metrics that are most relevant to your use case.
You can create custom dashboards with the dashboard designer.

- Each project can have an unlimited number of dashboards.
  The only limitation might be the [repository size limit](../project/repository/repository_size.md#size-and-storage-limits).
- Each dashboard can reference one or more [visualizations](#define-a-chart-visualization-template).
- Visualizations can be shared across dashboards.

Project maintainers can enforce approval rules on dashboard changes with features such as [code owners](../project/codeowners/_index.md) and [approval rules](../project/merge_requests/approvals/rules.md).
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

<!--- start_remove The following content will be removed on remove_date: '2025-03-20' -->

## Data explorer (deprecated)

> - Introduced in GitLab 16.4 [with a flag](../../administration/feature_flags.md) named `combined_analytics_visualization_editor`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/425048) in GitLab 16.7. Feature flag `combined_analytics_visualization_editor` removed.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/470875) from "Visualization designer" to "Data explorer" in GitLab 17.6.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/497577) in GitLab 17.7.

NOTE:
This feature is only compatible with the product analytics data source.

You can use the data explorer to explore available data.

<!--- end_remove -->

## View project dashboards

Prerequisites:

- You must have at least the Reporter role for the project.

To view a list of dashboards (both built-in and custom) for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. From the list of available dashboards, select the dashboard you want to view.

## View group dashboards

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390542) in GitLab 16.2 [with a flag](../../administration/feature_flags.md) named `group_analytics_dashboards`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/416970) in GitLab 16.8.
> - Feature flag `group_analytics_dashboards` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/439718) in GitLab 16.11.

Prerequisites:

- You must have at least the Reporter role for the group.

To view a list of dashboards (both built-in and custom) for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Analytics dashboards**.
1. From the list of available dashboards, select the dashboard you want to view.

## Change the location of dashboards

You can change the location of your project or group custom dashboards.

Prerequisites:

- You must have at least the Maintainer role for the project or group the project belongs to.

### Group dashboards

NOTE:
[Issue 411572](https://gitlab.com/gitlab-org/gitlab/-/issues/411572) proposes connecting this feature to group-level dashboards.

To change the location of a group's custom dashboards:

1. On the left sidebar, select **Search or go to** and find the project you want to store your dashboard files in.
   The project must belong to the group for which you create the dashboards.
1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Analytics**.
1. In the **Analytics Dashboards** section, select your dashboard files project.
1. Select **Save changes**.

### Project dashboards

By default custom dashboards are saved to the current project, because
dashboards are usually defined in the project where the analytics data is retrieved from.
However, you can also have a separate project for dashboards.
This setup is recommended if you want to enforce specific access rules to the dashboard definitions or share dashboards across multiple projects.

NOTE:
You can share dashboards only between projects that are located in the same group.

To change the location of project dashboards:

1. On the left sidebar, select **Search or go to** and find your project,
   or select **Create new** (**{plus}**) and **New project/repository**
   to create the project to store your dashboard files.
1. On the left sidebar, select **Search or go to** and find the analytics project.
1. Select **Settings > Analytics**.
1. In the **Analytics Dashboards** section, select your dashboard files project.
1. Select **Save changes**.

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

<!--- start_remove The following content will be removed on remove_date: '2025-03-20' -->

## Create a custom visualization (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/497577) in GitLab 17.7.

To create a custom visualization:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. Select **Data explorer**.
1. In the **Visualization title** field, enter the name of your visualization.
1. From the **Visualization type** dropdown list, select a visualization type.
1. In the **What metric do you want to visualize?** section, select a [measure or a dimension](#visualization-query-builder).
1. Select **Save**.

After you save a visualization, you can add it to a new or existing custom dashboard in the same project.

### Generate a custom visualization with GitLab Duo

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab.com
**Status:** Experiment

> - Introduced in GitLab 16.11 as an [experiment](../../policy/development_stages_support.md#experiment) feature [with a flag](../../administration/feature_flags.md) named `generate_cube_query`. Disabled by default.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

Prerequisites:

- The top-level group of the project must have GitLab Duo
  [experiment and beta features enabled](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).

To generate a custom visualization with GitLab Duo using a natural language query:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. Select **Data explorer**.
1. In the **Visualization title** field, enter the name of your visualization.
1. From the **Visualization type** dropdown list, select a visualization type.
1. In the **Generate with GitLab Duo** section, enter your prompt. For example:

   - _Daily sessions_
   - _Number of unique users, grouped weekly_
   - _Which are the most popular pages?_
   - _How many unique users does each browser have?_

1. Select **Generate with GitLab Duo**.
1. Select **Save**.

After you save a visualization, you can add it to a new or existing custom dashboard in the same project.

Provide feedback on this experimental feature in [issue 455363](https://gitlab.com/gitlab-org/gitlab/-/issues/455363).

### Visualization query builder

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14098) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `analytics_visualization_designer_filtering`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/469461) in GitLab 17.2. Feature flag `analytics_visualization_designer_filtering` removed.

You can use measures and dimensions to filter and refine the results of a custom visualization:

- Measures: Properties that can be calculated. Measures are aggregated by default.
- Dimensions: Attributes related to a measure. You can add multiple dimensions to a measure.

You can filter by custom event names with select measures:

- `Tracked events count`
- `Tracked events unique user count`

NOTE:
When you change or remove a measure then dependent dimensions may also be removed.

<!--- end_remove -->

## Create a dashboard by configuration

For more complex use cases, you can also create dashboards manually by configuration.

To define a dashboard:

1. In `.gitlab/analytics/dashboards/`, create a directory named like the dashboard.

   Each dashboard should have its own directory.
1. In the new directory, create a `.yaml` file with the same name as the directory, for example `.gitlab/analytics/dashboards/my_dashboard/my_dashboard.yaml`.

   This file contains the dashboard definition. It must conform to the JSON schema defined in `ee/app/validators/json_schemas/analytics_dashboard.json`.
1. Optional. To create new visualizations to add to your dashboard, see [defining a chart visualization template](#define-a-chart-visualization-template).

For [example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/product_analytics/dashboards/audience.yaml), if you want to create three dashboards (Conversion funnels, Demographic breakdown, and North star metrics)
and one visualization (line chart) that applies to all dashboards, the file structure looks like this:

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

### Dashboard filters

Dashboards support the following filters:

- **Date range**: Date selector to filter data by date.
- **Anonymous users**: Toggle to include or exclude anonymous users from the dataset.

To enable filters, in the `.yaml` configuration file set the filter's `enabled` option to `true`:

```yaml
title: My dashboard
...
filters:
  excludeAnonymousUsers:
    enabled: true
  dateRange:
    enabled: true
```

See a complete [dashboard configuration example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/product_analytics/dashboards/audience.yaml).

### Define an inline chart visualization

You can define different charts and add visualization options to some of them, such as:

- Line chart, with the options listed in the [ECharts documentation](https://echarts.apache.org/en/option.html).
- Column chart, with the options listed in the [ECharts documentation](https://echarts.apache.org/en/option.html).
- Data table.
- Single stat, with the only option to set `decimalPlaces` (number, default value is 0).

To add an inline chart visualization to a dashboard, see our [Create a built-in dashboard](../../development/fe_guide/analytics_dashboards.md#create-a-built-in-dashboard) guide.
This process can also be followed for user-created dashboards. Each visualization must be written with the following
required fields:

- version
- type
- data
- options

To contribute, see [adding a new visualization render type](../../development/fe_guide/analytics_dashboards.md#adding-a-new-visualization-render-type).

### Define a chart visualization template

NOTE:
We recommend using visualization templates sparingly. Visualization templates can lead to long visualization
selection lists in the dashboard editor UI if not managed, which may lead to visualizations being missed or duplicated.
Generally, visualization templates should be reserved for visualizations that will be used identically
across several dashboards.

If you need a visualization to be used by multiple dashboards, you might store them as separate template files.
When added to a dashboard, the visualization template will be copied over to the dashboard. Visualization templates
copied to dashboards are not updated when the visualization template is updated.

To define a chart visualization template for your dashboards:

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

## Troubleshooting

### `Something went wrong while loading the dashboard.`

If the dashboard displays a global error message that data could not be loaded, first try reloading the page.
If the error persists:

- Check that your configurations match the [dashboard JSON schema](../../development/fe_guide/analytics_dashboards.md) defined in `ee/app/validators/json_schemas/analytics_dashboard.json`.

### `Invalid dashboard configuration`

If the dashboard displays a global error message that the configuration is invalid, check that your configurations match the [dashboard JSON schema](../../development/fe_guide/analytics_dashboards.md) defined in `ee/app/validators/json_schemas/analytics_dashboard.json`.

### `Invalid visualization configuration`

If a dashboard panel displays a message that the visualization configuration is invalid,
check that your visualization configurations match the [visualization JSON schema](#define-a-chart-visualization-template)
defined in `ee/app/validators/json_schemas/analytics_visualization.json`.

### Dashboard panel error

If a dashboard panel displays an error message:

- Make sure your [visualization](../analytics/analytics_dashboards.md#define-a-chart-visualization-template) configuration is set up correctly.
