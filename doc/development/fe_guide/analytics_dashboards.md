---
stage: Monitor
group: Platform Insights
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Analytics dashboards
---

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98610) in GitLab 15.5 as an [experiment](../../policy/development_stages_support.md#experiment).
- Inline visualizations configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/509111) in GitLab 17.9.

{{< /history >}}

Analytics dashboards provide a configuration-based [dashboard](https://design.gitlab.com/patterns/dashboards)
structure, which is used to render and modify dashboard configurations created by GitLab or users.

{{< alert type="note" >}}

Analytics dashboards is intended for Premium and Ultimate subscriptions.

{{< /alert >}}

## Customizable dashboard framework (deprecated)

{{< history >}}

- [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191174) in GitLab 18.1.

{{< /history >}}

Analytics dashboards utilizes a deprecated component, [customizable_dashboard.vue](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/assets/javascripts/vue_shared/components/customizable_dashboard), 
to render the dashboard layout. As part the dashboard foundations epic [#18072](https://gitlab.com/groups/gitlab-org/-/epics/18072)
we are updating Analytics dashboards to utilize a new customizable dashboard component that uses
the new [dashboard layout framework](dashboard_layout_framework.md) in issue [#542166](https://gitlab.com/gitlab-org/gitlab/-/issues/542166).

Note that we are currently migrating the dashboard layout framework components to GitLab UI as part of issue [#542162](https://gitlab.com/gitlab-org/gitlab/-/issues/542162).
During this transition period, components may be located in either the legacy system or in GitLab UI.

## Overview

Analytics dashboard can be broken down into the following logical components:

- Dashboard: The container that organizes and displays all visualizations
- Panels: Individual sections that host visualizations
- Visualizations: Data display templates (charts, tables, etc.)
- Data sources: Connections to the underlying data

### Dashboard

A dashboard combines a collection of data sources, panels and visualizations into a single page to visually represent data.

Each panel in the dashboard queries the relevant data source and displays the resulting data as the specified visualization. Visualizations serve as templates for how to display data and can be reused across different panels.

A typical dashboard structure looks like this:

```plaintext
dashboard
├── panelA
│  └── visualizationX
│      └── datasource1
├── panelB
│  └── visualizationY
│      └── datasource2
├── panelC
│  └── visualizationY
│      └── datasource1
```

#### Dashboard filters

Dashboards support the following filters:

- **Date range**: Date selector to filter data by date.
- **Anonymous users**: Toggle to include or exclude anonymous users from the dataset.
- **Project**: Dropdown list to filter data by project.
- **Filtered search**: Filter bar to filter data by selected attributes.

#### Dashboard status

Dashboards with a `status` badge indicate their [development stage](../../policy/development_stages_support.md) and functionality. Dashboards without a `status` badge are fully developed and production-ready.

The supported options are:

- `experiment`
- `beta`

### Panel

Panels form the foundation of a dashboard and act as containers for your visualizations. Each panel is built using the GitLab standardized UI component called [GlDashboardPanel](https://gitlab-org.gitlab.io/gitlab-ui/?path=/docs/dashboards-dashboards-panel--docs).

### Visualization

A visualization transforms your data into a graphical format like a chart or table. You can use the following standard visualization types:

- LineChart
- ColumnChart
- DataTable
- SingleStats

For a list of all supported visualization types, see `AnalyticsVisualization.type` enum in [`analytics_visualization`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_visualization.json).
You're not limited to these options though - you can create new visualization types as needed.

### Data source

A data source is a connection to a database, an endpoint or a collection of data which can be used by your dashboard to query, retrieve, filter, and visualize results.
While there's a core set of supported data sources (see `Data.type` enum in [`analytics_visualizations`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_visualization.json)), you can add new ones to meet your needs.

To support all visualization types, ensure your data source returns data as a single aggregated value and a time series with a value for each point in time.

Note that each panel fetches data from the data source separately and independently from other panels.

## Create a built-in dashboard

GitLab provides predefined dashboards that are labeled **By GitLab**. Users cannot edit them, but they can clone or use them as the basis for creating similar custom dashboards.

To create a built-in analytics dashboard:

1. Create a folder for the new dashboard under `ee/lib/gitlab/analytics`, for example:

   ```plaintext
   ee/lib/gitlab/analytics/cool_dashboard
   ```

1. Create a dashboard configuration file (for example `dashboard.yaml`) in the new folder. The configuration must conform to the JSON schema defined in [`ee/app/validators/json_schemas/analytics_dashboard.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_dashboard.json). Example:

   ```yaml
   # cool_dashboard/dashboard.yaml
   ---
   title: My dashboard
   description: My cool dashboard
   panels: []
   ```

1. Optional. Enable dashboard filters by setting the filter's `enabled` option to `true` in the `.yaml` configuration file :

   ```yaml
   # cool_dashboard/dashboard.yaml
   ---
   title: My dashboard
   filters:
     excludeAnonymousUsers:
       enabled: true
     dateRange:
       enabled: true
     projects:
       enabled: true
     filteredSearch:
       enabled: true
       # Use `options` to define an array of tokens to override the default ones
       options:
         - token: assignee
           unique: false
         - token: label
           maxSuggestions: 10
   ```

   Refer to the `DashboardFilters` type in the [`ee/app/validators/json_schemas/analytics_dashboard.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_dashboard.json) for a list of supported filters.

1. Optional. Set the appropriate status of the dashboard if it is not production ready:

   ```yaml
   # cool_dashboard/dashboard.yaml
   ---
   title: My dashboard
   status: experiment
   ```

1. Optional. Create visualization templates by creating a folder for your templates (for example `visualizations/`) in your dashboard directory and
   add configuration files for each template.

   Visualization templates might be used when a visualization will be used by multiple dashboards. Use a template to
   prevent duplicating the same YAML block multiple times. For built-in dashboards, the dashboard
   will automatically update when the visualization template is changed. For user-defined dashboards, the visualization
   template is copied rather than referenced. Visualization templates copied to dashboards are not updated when the
   visualization template is updated.

   Each file must conform to the JSON schema defined in [`ee/app/validators/json_schemas/analytics_visualization.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_visualization.json).
   Example:

   ```yaml
   # cool_dashboard/visualizations/cool_viz.yaml
   ---
   version: 1
   type: LineChart    # The render type of the visualization.
   data:
     type: my_datasource    # The name of the datasource
     query: {}
   options: {}
   ```

   Both `query` and `options` objects will be passed to the data source and used to build the proper query.

   Refer to [Data source](#data-source) for a list of supported data sources, and [Visualization](#visualization) for a list of supported visualization render types.

1. To add panels to your dashboard that reference your visualizations, use either:
   - Recommended. Use an inline visualization within the dashboard configuration file:

     ```yaml
     # cool_dashboard/dashboard.yaml
     ---
     title: My dashboard
     description: My cool dashboard
     panels:
       - title: "My cool panel"
         visualization:
           version: 1
           slug: 'cool_viz' # Recommended to define a slug when a visualization is inline
           type: LineChart    # The render type of the visualization.
           data:
             type: my_datasource    # The name of the datasource
             query: {}
           options: {}
         gridAttributes:
           yPos: 0
           xPos: 0
           width: 3
           height: 1
     ```

     Both `query` and `options` objects will be passed to the data source and used to build the proper query.

     Refer to [Data source](#data-source) for a list of supported data sources, and [Visualization](#visualization) for a list of supported visualization render types.

   - Use a visualization template:

     ```yaml
     # cool_dashboard/dashboard.yaml
     ---
     title:  My dashboard
     description: My cool dashboard

     panels:
       - title: "My cool panel"
         visualization: cool_viz    # Must match the visualization config filename
         gridAttributes:
           yPos: 0
           xPos: 0
           width: 3
           height: 1
     ```

   The `gridAttributes` position the panel within a 12x12 dashboard grid, powered by [gridstack](https://github.com/gridstack/gridstack.js/tree/master/doc#item-options).

1. Register the dashboard by adding it to `builtin_dashboards` in [ee/app/models/analytics/dashboard.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/analytics/dashboard.rb).
   Here you can make your dashboard available at project-level or group-level (or both), restrict access based on feature flags, license or user role etc.

1. Optional. Register visualization templates by adding them to `get_path_for_visualization` in [ee/app/models/analytics/visualization.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/analytics/visualization.rb).

For a complete example, refer to the AI Impact [dashboard config](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/analytics/ai_impact_dashboard/dashboard.yaml).

### Adding a new data source

To add a new data source:

1. Create a new JavaScript module that exports a `fetch` method. See [analytics_dashboards/data_sources/index.js](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/data_sources/index.js) for the full documentation of the `fetch` API. You can also take a look at[`cube_analytics.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/data_sources/cube_analytics.js) as an example
1. Add your module to the list exports in [`data_sources/index.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/data_sources/index.js).
1. Add your data source to the schema's list of `Data` types in [`analytics_visualizations.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_visualization.json).

{{< alert type="note" >}}

Your data source must respect the filters so that all panels shows the same filtered data.

{{< /alert >}}

### Adding a new visualization render type

To add a new visualization render type:

1. Create a new Vue component that accepts `data` and `options` properties.
   See [`line_chart.vue`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/components/visualizations/line_chart.vue) as an example.
1. Add relevant storybook stories for the different states of the visualization
   See [`line_chart.stories.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/components/visualizations/line_chart.stories.js) as an example.
1. Add your component to the list of conditional components imports in [`analytics_dashboard_panel.vue`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/components/analytics_dashboard_panel.vue).
1. Add your component to the schema's list of `AnalyticsVisualization` enum type in [`analytics_visualization.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/analytics_visualization.json).

#### Migrating existing components to visualizations

You can migrate existing components to dashboard visualizations. To do this,
wrap your existing component in a new visualization that provides the component with the
required context and data. See [`dora_performers_score.vue`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/components/visualizations/dora_performers_score.vue) as an example.

As an upgrade path, your component may fetch its own data internally.
But you should ensure to plan how to migrate your visualization to use the shared analytics data sources method.
See [`value_stream.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/assets/javascripts/analytics/analytics_dashboards/data_sources/value_stream.js) as an example.

#### Introducing visualizations behind a feature flag

While developing new visualizations we can use [feature flags](../feature_flags/_index.md#create-a-new-feature-flag) to mitigate risks of disruptions or incorrect data for users.

The [`from_data`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/analytics/panel.rb) method builds the panel objects for a dashboard. Using the `filter_map` method, we can add a condition to skip rendering panels that include the visualization we are developing.

For example, here we have added the `enable_usage_overview_visualization` feature flag and can check it's current state to determine whether panels using the `usage_overview` visualization should be rendered:

```ruby
panel_yaml.filter_map do |panel|
  # Skip processing the usage_overview panel if the feature flag is disabled
  next if panel['visualization'] == 'usage_overview' && Feature.disabled?(:enable_usage_overview_visualization)

  new(
    title: panel['title'],
    project: project,
    grid_attributes: panel['gridAttributes'],
    query_overrides: panel['queryOverrides'],
    visualization: panel['visualization']
  )
end
```
