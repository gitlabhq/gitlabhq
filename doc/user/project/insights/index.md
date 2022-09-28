---
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Insights for projects **(ULTIMATE)**

Configure project insights to explore data such as:

- Issues created and closed during a specified period.
- Average time for merge requests to be merged.
- Triage hygiene.

Insights are also available for [groups](../../group/insights/index.md).

## View project insights

Prerequisites:

- You must have:
  - Access to a project to view information about its merge requests and issues.
  - Permission to view confidential merge requests and issues in the project.

To view project insights:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Insights**.
1. To view a report, select the **Select page** dropdown list.

## Configure project insights

Prerequisites:

- Depending on your project configuration, you must have at least the Developer role.

Project insights are configured with the [`.gitlab/insights.yml`](#insights-configuration-file) file in the project. If a project doesn't have a configuration file, it uses the [group configuration](../../group/insights/index.md#configure-your-insights).

The `.gitlab/insights.yml` file is a YAML file where you define:

- The structure and order of charts in a report.
- The style of charts displayed in the report of your project or group.

To configure project insights, either:

- Create a `.gitlab/insights.yml` file locally in the root directory of your project, and push your changes.
- Create a `.gitlab/insights.yml` file in the UI:
  1. On the top bar, select **Main menu > Projects** and find your project.
  1. Above the file list, select the branch you want to commit to, select the plus icon, then select **New file**.
  1. In the **File name** text box, enter `.gitlab/insights.yml`.
  1. In the large text box, update the file contents.
  1. Select **Commit changes**.

After you create the configuration file, you can also
[use it for the project's group](../../group/insights/index.md#configure-your-insights).

## Insights configuration file

In the `.gitlab/insights.yml` file:

- [Configuration parameters](#insights-configuration-parameters) define the chart behavior.
- Each report has a unique key and a collection of charts to fetch and display.
- Each chart definition is made up of a hash composed of key-value pairs.

The following example shows a single definition that displays one report with one chart.

```yaml
bugsCharts:
  title: "Charts for bugs"
  charts:
    - title: "Monthly bugs created"
      description: "Open bugs created per month"
      type: bar
      query:
        data_source: issuables
        params:
          issuable_type: issue
          issuable_state: opened
          filter_labels:
            - bug
          group_by: month
          period_limit: 24
```

## Insights configuration parameters

The following table lists the chart parameters:

| Keyword                                            | Description |
|:---------------------------------------------------|:------------|
| [`title`](#title)                                  | The title of the chart. This displays on the Insights page. |
| [`description`](#description)                      | A description for the individual chart. This displays above the relevant chart. |
| [`type`](#type)                                    | The type of chart: `bar`, `line` or `stacked-bar`. |
| [`query`](#query)                                  | A hash that defines the data source and filtering conditions for the chart. |

### `title`

`title` is the title of the chart as it displays on the Insights page.
For example:

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
```

### `description`

The `description` text is displayed above the chart, but below the title. It's used
to give extra details regarding the chart, for example:

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
```

### `type`

`type` is the chart type.

For example:

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  type: bar
```

Supported values are:

| Name  | Example |
| ----- | ------- |
| `bar` | ![Insights example bar chart](img/insights_example_bar_chart.png) |
| `bar` (time series, that is when `group_by` is used) | ![Insights example bar time series chart](img/insights_example_bar_time_series_chart.png) |
| `line` | ![Insights example stacked bar chart](img/insights_example_line_chart.png) |
| `stacked-bar` | ![Insights example stacked bar chart](img/insights_example_stacked_bar_chart.png) |

NOTE:
The `dora` data source supports the `bar` and `line` chart types.

### `query`

`query` allows to define the data source and various filtering conditions for the chart.

Example:

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
  type: bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
      collection_labels:
        - S1
        - S2
        - S3
        - S4
      group_by: week
      period_limit: 104
```

The legacy format without the `data_source` parameter is still supported:

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
  type: bar
  query:
    issuable_type: issue
    issuable_state: opened
    filter_labels:
      - bug
    collection_labels:
      - S1
      - S2
      - S3
      - S4
    group_by: week
    period_limit: 104
```

#### `query.data_source`

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/725) in GitLab 15.3.

The `data_source` parameter was introduced to allow visualizing data from different data sources.

Supported values are:

- `issuables`: Exposes merge request or issue data.
- `dora`: Exposes DORA metrics data.

#### `Issuable` query parameters

##### `query.params.issuable_type`

Defines the type of "issuable" you want to create a chart for.

Supported values are:

- `issue`: The chart displays issues' data.
- `merge_request`: The chart displays merge requests' data.

##### `query.params.issuable_state`

Filter by the current state of the queried "issuable".

By default, the `opened` state filter is applied.

Supported values are:

- `opened`: Open issues / merge requests.
- `closed`: Closed Open issues / merge requests.
- `locked`: Issues / merge requests that have their discussion locked.
- `merged`: Merged merge requests.
- `all`: Issues / merge requests in all states

##### `query.params.filter_labels`

Filter by labels currently applied to the queried "issuable".

By default, no labels filter is applied. All the defined labels must be
currently applied to the "issuable" in order for it to be selected.

Example:

```yaml
monthlyBugsCreated:
  title: "Monthly regressions created"
  type: bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
        - regression
```

##### `query.params.collection_labels`

Group "issuable" by the configured labels.

By default, no grouping is done. When using this keyword, you need to
set `type` to either `line` or `stacked-bar`.

Example:

```yaml
weeklyBugsBySeverity:
  title: "Weekly bugs by severity"
  type: stacked-bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
      collection_labels:
        - S1
        - S2
        - S3
        - S4
```

##### `query.group_by`

Define the X-axis of your chart.

Supported values are:

- `day`: Group data per day.
- `week`: Group data per week.
- `month`: Group data per month.

##### `query.period_limit`

Define how far "issuables" are queried in the past (using the `query.period_field`).

The unit is related to the `query.group_by` you defined. For instance if you
defined `query.group_by: 'day'`  then `query.period_limit: 365` would mean
"Gather and display data for the last 365 days".

By default, default values are applied depending on the `query.group_by`
you defined.

| `query.group_by` | Default value |
| ---------------- | ------------- |
| `day`            | 30            |
| `week`           | 4             |
| `month`          | 12            |

#### `query.period_field`

Define the timestamp field used to group "issuables".

Supported values are:

- `created_at` (default): Group data using the `created_at` field.
- `closed_at`: Group data using the `closed_at` field (for issues only).
- `merged_at`: Group data using the `merged_at` field (for merge requests only).

The `period_field` is automatically set to:

- `closed_at` if `query.issuable_state` is `closed`
- `merged_at` if `query.issuable_state` is `merged`
- `created_at` otherwise

NOTE:
Until [this bug](https://gitlab.com/gitlab-org/gitlab/-/issues/26911), is resolved,
you may see `created_at` in place of `merged_at`. `created_at` is used instead.

#### `DORA` query parameters

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367248) in GitLab 15.3.

An example DORA chart definition:

```yaml
dora:
  title: "DORA charts"
  charts:
    - title: "DORA deployment frequency"
      type: bar # or line
      query:
        data_source: dora
        params:
          metric: deployment_frequency
          group_by: day
          period_limit: 10
      projects:
        only:
          - 38
    - title: "DORA lead time for changes"
      description: "DORA lead time for changes"
      type: bar
      query:
        data_source: dora
        params:
          metric: lead_time_for_changes
          group_by: day
          environment_tiers:
            - staging
          period_limit: 30
```

##### `query.metric`

Defines which DORA metric to query. The available values are:

- `deployment_frequency` (default)
- `lead_time_for_changes`
- `time_to_restore_service`
- `change_failure_rate`

The metrics are described on the [DORA API](../../../api/dora/metrics.md#the-value-field) page.

##### `query.group_by`

Define the X-axis of your chart.

Supported values are:

- `day` (default): Group data per day.
- `month`: Group data per month.

##### `query.period_limit`

Define how far the metrics are queried in the past (default: 15). Maximum lookback period is 180 days or 6 months.

##### `query.environment_tiers`

An array of environments to include into the calculation (default: production). Available options: `production`, `staging`, `testing`, `development`, `other`.

### `projects`

You can limit where the "issuables" can be queried from:

- If `.gitlab/insights.yml` is used for a [group's insights](../../group/insights/index.md#configure-your-insights), with `projects`, you can limit the projects to be queried. By default, all projects currently under the group are used.
- If `.gitlab/insights.yml` is used for a project's insights, specifying any other projects yields no results. By default, the project itself is used.

#### `projects.only`

The `projects.only` option specifies the projects which the "issuables"
should be queried from.

Projects listed here are ignored when:

- They don't exist.
- The current user doesn't have sufficient permissions to read them.
- They are outside of the group.

In the following `insights.yml` example, we specify the projects
the queries are used on. This example is useful when setting
a group's insights:

```yaml
monthlyBugsCreated:
  title: "Monthly bugs created"
  description: "Open bugs created per month"
  type: bar
  query:
    data_source: issuables
    params:
      issuable_type: issue
      issuable_state: opened
      filter_labels:
        - bug
  projects:
    only:
      - 3                         # You can use the project ID
      - groupA/projectA           # Or full project path
      - groupA/subgroupB/projectC # Projects in subgroups can be included
      - groupB/project            # Projects outside the group will be ignored
```

## Complete example

```yaml
.projectsOnly: &projectsOnly
  projects:
    only:
      - 3
      - groupA/projectA
      - groupA/subgroupB/projectC

bugsCharts:
  title: "Charts for bugs"
  charts:
    - title: "Monthly bugs created"
      description: "Open bugs created per month"
      type: bar
      <<: *projectsOnly
      query:
        data_source: issuables
        params:
          issuable_type: issue
          issuable_state: opened
          filter_labels:
            - bug
          group_by: month
          period_limit: 24

    - title: "Weekly bugs by severity"
      type: stacked-bar
      <<: *projectsOnly
      query:
        data_source: issuables
        params:
          issuable_type: issue
          issuable_state: opened
          filter_labels:
            - bug
          collection_labels:
            - S1
            - S2
            - S3
            - S4
          group_by: week
          period_limit: 104

    - title: "Monthly bugs by team"
      type: line
      <<: *projectsOnly
      query:
        data_source: issuables
        params:
          issuable_type: merge_request
          issuable_state: opened
          filter_labels:
            - bug
          collection_labels:
            - Manage
            - Plan
            - Create
          group_by: month
          period_limit: 24
```
