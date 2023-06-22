---
stage: Analyze
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Analytics dashboards (Experiment) **(ULTIMATE)**

> Introduced in GitLab 15.9 as an [Experiment](../../policy/experiment-beta-support.md#experiment) feature [with a flag](../../administration/feature_flags.md) named `combined_analytics_dashboards`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `combined_analytics_dashboards`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

## Dashboards

Each project can have an unlimited number of dashboards, only limited by the instances [repository size limits](../project/repository/reducing_the_repo_size_using_git.md#storage-limits).
These dashboards are defined using the GitLab YAML schema, and stored in the `.gitlab/analytics/dashboards/` directory of a project repository.
The dashboard file name and containing directory should be the same, for example `my_dashboard/my_dashboard.yaml`. For more information see [defining a dashboard](#define-a-dashboard).
Each dashboard can reference one or more [visualizations](#define-a-chart-visualization), which are shared across dashboards.

Project maintainers can enforce approval rules on dashboard changes using features such as [code owners](../project/codeowners/index.md) and [approval rules](../project/merge_requests/approvals/rules.md).
Your dashboard files are versioned in source control with the rest of a project's code.

### Data sources

A data source is a connection to a database or collection of data which can be used by your dashboard
filters and visualizations to query and retrieve results.

The following data sources are configured for analytics dashboards:

- [Product analytics](../product_analytics/index.md)

### View project dashboards

To view a list of dashboards for a project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Analyze > Dashboards**.
1. From the list of available dashboards, select the dashboard you want to view.

### Define a dashboard

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

### Define a chart visualization

You can define different charts, and add visualization options to some of them:

- Line chart, with the options listed in the [ECharts documentation](https://echarts.apache.org/en/option.html).
- Column chart, with the options listed in the [ECharts documentation](https://echarts.apache.org/en/option.html).
- Data table, with the only option to render `links` (array of objects, each with `text` and `href` properties to specify the dimensions to be used in links). See [example](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_visualization.json?ref_type=heads#L112)).
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

### Change the location of project dashboards

Dashboards are usually defined in the project where analytics data is being retrieved.
However, you can also have a separate project for dashboards.
This is recommended if you want to enforce specific access rules to the dashboard definitions or share dashboards across multiple projects.

NOTE:
You can share dashboards only between projects that are located in the same group.

To change the location of project dashboards:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project,
   or select **Create new** (**{plus}**) and **New project/repository**
   to create the project to store your dashboard files.
1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) and find the project you want to use the dashboards for.
1. Select **Settings > General**.
1. Expand **Analytics**.
1. In the **Analytics Dashboards** section, select the project that contains the dashboard files.
1. Select **Save changes**.

### Change the location of group dashboards

NOTE:
This feature will be connected to group-level dashboards in [issue 411572](https://gitlab.com/gitlab-org/gitlab/-/issues/411572).

If you want to use dashboards for a group, you must store the dashboard files in a project that belongs to that group.
You can change the source project of a group's dashboards at any time.

To change the location of a group's dashboards:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Settings > General**.
1. Expand **Analytics**.
1. In the **Analytics Dashboards** section, select the project that contains the dashboard files.
1. Select **Save changes**.

## Dashboards designer

> Introduced in GitLab 16.1 [with a flag](../../administration/feature_flags.md) named `combined_analytics_dashboards_editor`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `combined_analytics_dashboards_editor`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

NOTE:
This feature does not work in conjunction with the `product_analytics_snowplow_support` feature flag.

You can use the dashboards designer to:

- Create custom dashboards
- Rename custom dashboards
- Add visualizations to new and existing custom dashboards
- Resize or move panels within custom dashboards

You cannot edit the built-in dashboards labeled as `By GitLab`.
To edit these dashboards you should create a new custom dashboard which uses the same visualizations.

### Create a custom dashboard

To create a custom dashboard:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Analyze > Dashboards**.
1. Select **New dashboard**.
1. In the **New dashboard** input, enter the name of the dashboard.
1. From the **Add visualizations** list on the right, select the visualizations to add to the dashboard.
1. Optional. Drag or resize the selected panel how you prefer.
1. Select **Save**.

### Edit a custom dashboard

You can edit your custom dashboard's title and add or resize visualizations within the dashboard designer.

To edit an existing custom dashboard:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Analyze > Dashboards**.
1. From the list of available dashboards, select a custom dashboard (one without the `By GitLab` label) you want to edit.
1. Select **Edit**.
1. Optional. Change the title of the dashboard.
1. Optional. From the **Add visualizations** list on the right, select other visualizations to add to the dashboard.
1. Optional. In the dashboard, select a panel and drag or resize it how you prefer.
1. Select **Save**.
