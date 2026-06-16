---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GLQL display types
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14767) in GitLab 17.4 [with a flag](../../administration/feature_flags/_index.md) named `glql_integration`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/554870) in GitLab 18.3. Feature flag `glql_integration` removed.

{{< /history >}}

A display type controls how an [embedded view](_index.md#embedded-views) renders the results of a
GLQL query. Set the display type with the `display` parameter in the view source.

If you do not set a `display` parameter, results render as a list.

Some display types work with any query. Others work only in
[analytics mode](_index.md#analytics-mode), which aggregates data into dimensions and metrics.

The following display types are available in any mode:

| Display type                  | `display` value | Description |
| ----------------------------- | --------------- | ----------- |
| Table               | `table`         | A table with one row per result and one column per field. |
| List                 | `list`          | An unordered list of results. |
| Ordered list | `orderedList`   | A numbered list of results. |

The following display types are available only in analytics mode:

| Display type                  | `display` value | Description |
| ----------------------------- | --------------- | ----------- |
| Column chart | `columnChart`   | A chart that compares metrics across the categories defined by your dimensions. |
| Line chart     | `lineChart`     | A chart that plots one or more metrics as lines over a dimension, to show trends. |

## Table

A table renders one row per result and one column per [field](fields.md).

To sort a table by a column, select the column header. This view reorders the rows loaded in
the view, not the full result set.

### Example

To display the first five open issues assigned to the current user in the `gitlab-org/gitlab`
project as a table, with the `title`, `state`, `health`, `epic`, `milestone`, `weight`, and
`updated` columns:

````yaml
```glql
display: table
title: My open issues
fields: title, state, health, epic, milestone, weight, updated
limit: 5
query: type = Issue AND project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````

## List

A list renders results as an unordered list. Lists are the default display type.

### Example

To display the first five open issues assigned to the current user in the `gitlab-org/gitlab`
project as a list, sorted by due date with the earliest first, and showing the `title`, `health`,
and `due` fields:

````yaml
```glql
display: list
fields: title, health, due
limit: 5
sort: due asc
query: type = Issue AND project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````

## Ordered list

An ordered list renders results as a numbered list.
Use an ordered list when the order of the results is meaningful, such as a ranking.

### Example

To display the first five open issues assigned to the current user in the `gitlab-org/gitlab`
project as an ordered list, sorted by due date with the earliest first, and showing the `title`,
`health`, and `due` fields:

````yaml
```glql
display: orderedList
fields: title, health, due
limit: 5
sort: due asc
query: type = Issue AND project = "gitlab-org/gitlab" AND assignee = currentUser() AND state = opened
```
````

## Column chart

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/21212) in GitLab 19.1.

{{< /history >}}

A column chart visualizes aggregated data from [analytics mode](_index.md#analytics-mode).
Use a column chart to compare metrics across the categories defined by your dimensions.

A column chart requires:

- Analytics mode, set with `mode: analytics`.
- One or two `dimensions` to group results by.
- At least one metric to plot (using the `metrics` parameter).

The number of dimensions and metrics determines how the chart renders:

- One dimension with one or more metrics plots a column for each metric. To stack these columns,
  set `stacked: true` under `displayConfig`.
- Two dimensions with one metric plots a stacked column chart grouped by the second dimension.
  With two dimensions, you can use only one metric.

### Example

To display Code Suggestions usage by language over the last 30 days as a column chart:

````yaml
```glql
display: columnChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount
```
````

To stack the metrics into a single column instead of plotting them side by side:

````yaml
```glql
display: columnChart
displayConfig:
  stacked: true
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: acceptedCount, rejectedCount
```
````

## Line chart

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240016) in GitLab 19.1.

{{< /history >}}

A line chart visualizes aggregated data from [analytics mode](_index.md#analytics-mode) as one or
more lines. Use a line chart to show how metrics change across a dimension, such as over time.

A line chart requires:

- Analytics mode, set with `mode: analytics`.
- Exactly one `dimension` for the x-axis.
- At least one `metric` to plot. Each metric renders as a separate line.

### Example

To display Code Suggestions usage by language over the last 30 days as a line chart, with one line
for total suggestions and one for accepted suggestions:

````yaml
```glql
display: lineChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount, acceptedCount
```
````

## Pagination support

Display types available in any mode display the first page of results and provide a **Load more**
action to fetch additional pages. For more information, see [pagination](_index.md#pagination).

Analytics mode visualizations don't support pagination. They render all aggregated results at once.
