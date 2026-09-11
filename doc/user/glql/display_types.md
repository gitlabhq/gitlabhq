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

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/14767) in GitLab 17.4 [with a feature flag](../../administration/feature_flags/_index.md) named `glql_integration`. Disabled by default.
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
| Single stat | `stat`          | A single aggregated metric, displayed as a large value. |
| Column chart | `columnChart`   | A chart that compares metrics across the categories defined by your dimensions. |
| Bar chart | `barChart` | A horizontal chart that compares metrics across the categories defined by your dimensions. |
| Bar list | `barList` | A horizontal chart that shows each dimension value as a share of the total. |
| Line chart     | `lineChart`     | A chart that plots one or more metrics as lines over a dimension, to show trends. |
| Area chart     | `areaChart`     | A chart that plots one or more metrics as filled areas over a dimension, to show trends and volume. |
| Heat map     | `heatMap`     | A grid of shaded cells, one per pair of dimension values, where a darker cell is a larger value. |
| Diverging bar chart | `divergingBarChart` | A chart that mirrors two metrics around a shared category column, each scaled to its own largest bar. |

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

## Single stat

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241395) in GitLab 19.2.

{{< /history >}}

A single stat visualizes one aggregated metric from [analytics mode](_index.md#analytics-mode) as a
large value. Use a single stat to highlight a key number, such as a total or a rate.

A single stat requires:

- Analytics mode, set with `mode: analytics`.
- Only one metric, set with the `metrics` parameter.
- No `dimensions`.

Values format automatically based on the metric. For example, counts use thousands separators and
rates display as percentages.

### Example

To display the total number of Code Suggestions over the last 30 days as a single stat:

````yaml
```glql
display: stat
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
metrics: totalCount
```
````

## Column chart

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21212) in GitLab 19.1.

{{< /history >}}

A column chart visualizes aggregated data from [analytics mode](_index.md#analytics-mode).
Use a column chart to compare metrics across the categories defined by your dimensions.

A column chart requires:

- Analytics mode, set with `mode: analytics`.
- One or two `dimensions` to group results by.
- At least one metric to plot (using the `metrics` parameter).

The number of dimensions and metrics determines how the chart renders:

- One dimension with one or more metrics plots a column for each metric. To stack these columns,
  set `stacked: true` under `displayConfig`. With a single metric, `stacked` has no visible effect.
- Two dimensions with one metric plots a stacked column chart grouped by the second dimension.
  With two dimensions, you can use only one metric, and GitLab ignores `displayConfig.stacked`.

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

## Bar chart

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21212) in GitLab 19.2.

{{< /history >}}

A bar chart visualizes aggregated data from [analytics mode](_index.md#analytics-mode) as
horizontal bars. Use a bar chart to compare metrics across the categories defined by your
dimensions, especially when category labels are long.

A bar chart requires:

- Analytics mode, set with `mode: analytics`.
- One or two `dimensions` to group results by.
- At least one metric to plot (using the `metrics` parameter).

The number of dimensions and metrics determines how the chart renders:

- One dimension with one or more metrics plots a bar for each metric. To stack these bars,
  set `stacked: true` under `displayConfig`. With a single metric, `stacked` has no visible effect.
- Two dimensions with one metric plots a stacked bar chart grouped by the second dimension.
  With two dimensions, you can use only one metric, and GitLab ignores `displayConfig.stacked`.

### Example

To display Code Suggestions usage by language over the last 30 days as a bar chart:

````yaml
```glql
display: barChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount
```
````

To stack the metrics into a single bar instead of plotting them side by side:

````yaml
```glql
display: barChart
displayConfig:
  stacked: true
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: acceptedCount, rejectedCount
```
````

## Bar list

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/623319) in GitLab 19.4.

{{< /history >}}

A bar list visualizes aggregated data from [analytics mode](_index.md#analytics-mode) as
horizontal bars, where each bar's length is that row's percentage of the total of all rows, not a
comparison against the largest row. A bar list answers "what share of the whole is this", while a
bar chart answers "how do these compare to each other".

A bar list requires:

- Analytics mode, set with `mode: analytics`.
- Exactly one `dimensions` value.
- Exactly one metric, set with the `metrics` parameter.

More than one dimension causes a validation error in the view. A query that names more than
one metric renders the first and ignores the rest.

Rows sort in descending order by value. Each row's label shows the percentage and the value.

By default, a bar list shows six rows plus an `Other (N)` roll-up row, so a query that returns
eight or more rows always has an `Other` row. A query that returns seven or fewer rows shows
every row, because folding a single row would hide its name without making the list shorter.
To show a different number of rows, set `maxRows` under `displayConfig` to a whole
number greater than zero. GitLab keeps that many of the highest-value rows and folds the rest
into a single row named `Other (N)`, where `N` is the number of rows folded in and the value is
their combined total. A value that is not a whole number greater than zero falls back to six.

A share of the total is meaningful only when the metric is a count or a sum. For a metric such as
an average or a median, the total behind the shares has no meaning.

### Example

To display Code Suggestions usage by language over the last 30 days as a bar list:

````yaml
```glql
display: barList
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount
```
````

To show more than the default six rows:

````yaml
```glql
display: barList
displayConfig:
  maxRows: 10
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: language
metrics: totalCount
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

## Area chart

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/glql/-/work_items/103) in GitLab 19.3.

{{< /history >}}

An area chart visualizes aggregated data from [analytics mode](_index.md#analytics-mode) as one or
more filled areas. Use an area chart to show how metrics change across a dimension, such as over
time, and to emphasize the volume behind the trend.

An area chart requires:

- Analytics mode, set with `mode: analytics`.
- One or two `dimensions` to group results by.
- At least one metric to plot (using the `metrics` parameter).

The number of dimensions and metrics determines how the chart renders:

- One dimension with one or more metrics plots an area for each metric. Areas overlap with
  semi-transparent fills. To stack the areas cumulatively instead, set `stacked: true` under
  `displayConfig`. With a single metric, `stacked` has no visible effect.
- Two dimensions with one metric plots a stacked area chart grouped by the second dimension.
  With two dimensions, you can use only one metric, and GitLab ignores `displayConfig.stacked`.

### Example

To display shown and accepted Code Suggestions over the last 30 days as overlapping areas:

````yaml
```glql
display: areaChart
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: timestamp
metrics: shownCount, acceptedCount
```
````

To stack the metrics cumulatively instead:

````yaml
```glql
display: areaChart
displayConfig:
  stacked: true
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: timestamp
metrics: shownCount, acceptedCount
```
````

## Heat map

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/628031) in GitLab 19.4.

{{< /history >}}

A heat map visualizes aggregated data from [analytics mode](_index.md#analytics-mode) as a grid of
shaded cells, one cell per pair of dimension values. Use a heat map to compare a single metric across
two dimensions at once, and to see where the largest values sit.

A heat map requires:

- Analytics mode, set with `mode: analytics`.
- Exactly two `dimensions` to group results by. The first runs along the columns, the second down
  the rows.
- Exactly one metric to shade the cells by (using the `metrics` parameter).

Each cell shows its value, shaded from light to dark as the value rises. Shading uses fixed bands
derived from the values in the result, so a darker cell always means a larger value. Cells with no
value at all are shaded a neutral gray rather than the lightest color, so that a small value is not
mistaken for an absent one. Hover a cell for its row, column, and exact value.

To describe the panel above the grid, set `description` under `displayConfig`.

### Example

To compare Code Suggestion volume across IDEs and languages over the last 30 days:

````yaml
```glql
display: heatMap
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: ideName, language
metrics: totalCount
```
````

To add a description above the grid:

````yaml
```glql
display: heatMap
displayConfig:
  description: Code Suggestions accepted per language, by IDE.
mode: analytics
query: type = CodeSuggestion and timestamp >= -30d
dimensions: ideName, language
metrics: acceptedCount
```
````

## Diverging bar chart

A diverging bar chart visualizes aggregated data from [analytics mode](_index.md#analytics-mode)
as two metrics mirrored around a shared, centered category column. Bars for the first metric grow
leftward from the center, and bars for the second metric grow rightward. Use a diverging bar chart
to compare two metrics across categories when one metric can dwarf the other in absolute terms.

Each half of the chart is scaled independently, to its own largest bar. This means a category can
be a small share of one metric and the bulk of the other, and both bars still fill their side of
the chart. Because the two halves use different scales, bar lengths are comparable only within a
half, never across the center.

A diverging bar chart requires:

- Analytics mode, set with `mode: analytics`.
- Exactly one value in `dimensions` to group results by.
- Exactly two metrics to plot (using the `metrics` parameter).

Anything other than exactly one dimension and exactly two metrics causes a validation error in the
view.

Rows render in the order the query returns them. Use `sort` to control this order, because a
diverging bar chart does not sort rows itself. Each metric's values are formatted in that metric's
own unit, so you can pair a count with a rate.

The category column is a share of the chart's width, so category labels that do not fit are
truncated. In a narrow panel, keep category names short.

There is no `displayConfig` option for this display type.

### Example

To compare the number of unique users against the total number of sessions for GitLab Duo
Agent Platform, grouped by flow type, over the last 30 days:

````yaml
```glql
display: divergingBarChart
mode: analytics
query: type = AgentPlatformSession and created >= -30d
dimensions: flowType
metrics: usersCount, totalCount
sort: totalCount desc
```
````

## Pagination support

Display types available in any mode display the first page of results and provide a **Load more**
action to fetch additional pages. For more information, see [pagination](_index.md#pagination).

Analytics mode visualizations don't support pagination. They render all aggregated results at once.
