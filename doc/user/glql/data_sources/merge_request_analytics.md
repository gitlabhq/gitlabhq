---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Merge request analytics
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21214) in GitLab 19.3.

{{< /history >}}

Analytics mode returns aggregated metrics for merge requests, with data
typically available within 10 minutes.

To query individual merge request records, use [Merge requests](merge_requests.md).

## Allowed scopes

| Scope     | Description                                                               |
| --------- | -------------------------------------------------------------------------- |
| `project` | Query merge requests in a specific project.                               |
| `group`   | Query merge requests across all projects in a group, including subgroups. |

For more information, see [scopes](_index.md#scopes).

## Query fields

| Field                              | Name           | Operators                 |
| ---------------------------------- | -------------- | ------------------------- |
| [Created at](#created-at)          | `created`      | `=`, `>`, `<`, `>=`, `<=` |
| [Merged at](#merged-at)            | `merged`       | `=`, `>`, `<`, `>=`, `<=` |
| [State](#state)                    | `state`        | `=`, `in`                 |
| [Target branch](#target-branch)    | `targetBranch` | `=`, `in`                 |

### Created at {#created-at}

**Description**: Filter merge requests by their creation date.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.

### Merged at {#merged-at}

**Description**: Filter merge requests by their merge date.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.

### State {#state}

**Description**: Filter merge requests by their state.

**Allowed value types**:

- `Enum`, one of `opened`, `closed`, `merged`, or `locked`
- `List` (use `in` operator for multiple values)

**Notes**:

- The `all` value is not supported. To include merge requests in all states, omit the filter.

### Target branch {#target-branch}

**Description**: Filter merge requests by their target branch.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

## Dimensions

| Dimension     | Name           | Description                              |
| ------------- | -------------- | ---------------------------------------- |
| Created at    | `created`      | Group by creation date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `daily`, `weekly`, or `monthly` (default: `weekly`). For example, `created(monthly)`. |
| Merged at     | `merged`       | Group by merge date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `daily`, `weekly`, or `monthly` (default: `weekly`). For example, `merged(monthly)`. |
| State         | `state`        | Group by merge request state.            |
| Target branch | `targetBranch` | Group by target branch.                  |

## Metrics

| Metric                 | Name                   | Description                              |
| ---------------------- | ---------------------- | ---------------------------------------- |
| Throughput count       | `throughputCount`      | Number of merged merge requests.         |
| Time to merge quantile | `timeToMergeQuantile`  | Time from creation to merge, rendered as a duration. For example, `1d 2h`. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.5`, the median). For example, `timeToMergeQuantile(0.95)`. |
| Total count            | `totalCount`           | Total number of merge requests.          |

## Sort fields

Sort by any field included in your selected dimensions or metrics. For more
information, see [analytics mode sorting](../_index.md#sorting).

## Examples

- Weekly merge request throughput trend for the last 30 days:

  ````yaml
  ```glql
  title: "Weekly merge request throughput (last 30 days)"
  display: table
  mode: analytics
  query: type = MergeRequest and project = "gitlab-org/gitlab" and merged > -30d
  dimensions: merged(weekly) as "Week"
  metrics: totalCount as "Total", throughputCount as "Merged", timeToMergeQuantile(0.5) as "Median time to merge"
  sort: merged desc
  ```
  ````

- Median and p95 time to merge by week:

  ````yaml
  ```glql
  title: "Median and p95 time to merge by week"
  display: table
  mode: analytics
  query: type = MergeRequest and project = "gitlab-org/gitlab" and merged > -90d
  dimensions: merged(weekly) as "Week"
  metrics: timeToMergeQuantile(0.5) as "Median time to merge", timeToMergeQuantile(0.95) as "p95 time to merge"
  sort: merged desc
  ```
  ````

- Merge requests grouped by state:

  ````yaml
  ```glql
  title: "Merge requests by state (last 30 days)"
  display: table
  mode: analytics
  query: type = MergeRequest and project = "gitlab-org/gitlab" and created > -30d
  dimensions: state as "State"
  metrics: totalCount as "Total"
  sort: totalCount desc
  ```
  ````

- Throughput per target branch across a group:

  ````yaml
  ```glql
  title: "Merge request throughput by target branch"
  display: table
  mode: analytics
  query: type = MergeRequest and group = "gitlab-org" and merged > -30d
  dimensions: targetBranch as "Target branch"
  metrics: totalCount as "Total", throughputCount as "Merged"
  sort: throughputCount desc
  ```
  ````

- Overall merge request count for a group, without grouping:

  ````yaml
  ```glql
  title: "Merge requests created in the last 7 days"
  display: table
  mode: analytics
  query: type = MergeRequest and group = "gitlab-org" and created > -7d
  metrics: totalCount as "Total"
  ```
  ````
