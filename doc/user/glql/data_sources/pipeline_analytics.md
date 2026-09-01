---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Pipeline analytics
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21212) in GitLab 19.1.
- [Changed](https://gitlab.com/gitlab-org/glql/-/merge_requests/416) to cover pipelines in all states, including in-progress pipelines, in GitLab 19.2.
- Configurable `granularity` and `quantile` parameters [introduced](https://gitlab.com/gitlab-org/glql/-/issues/130) in GitLab 19.3.

{{< /history >}}

Analytics mode returns aggregated metrics for pipelines in all states, including
in-progress pipelines, with data typically available within ten minutes.

To query individual pipeline records, use [Pipelines](pipelines.md).

## Allowed scopes

| Scope     | Description                                                          |
| --------- | -------------------------------------------------------------------- |
| `project` | Query pipelines in a specific project.                               |
| `group`   | Query pipelines across all projects in a group, including subgroups. |

## Query fields

Use these fields in the `query` parameter to filter your results.

| Field                                  | Name       | Operators                 |
| -------------------------------------- | ---------- | ------------------------- |
| [Finished at](#finished-at)         | `finished` | `=`, `>`, `<`, `>=`, `<=` |
| [Ref](#ref)                         | `ref`      | `=`, `in`                 |
| [Source](#source)                   | `source`   | `=`, `in`                 |
| [Started at](#started-at)           | `started`  | `=`, `>`, `<`, `>=`, `<=` |
| [Status](#status)                   | `status`   | `=`, `in`                 |

### Finished at {#finished-at}

**Description**: Filter pipelines by their finish date.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.

### Ref {#ref}

**Description**: Filter pipelines by the Git ref (branch or tag name) they ran on.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### Source {#source}

**Description**: Filter pipelines by their trigger event.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### Started at {#started-at}

**Description**: Filter pipelines by their start date.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.

### Status {#status}

**Description**: Filter pipelines by their CI/CD status.

**Allowed value types**:

- `Enum`, one of `canceled`, `canceling`, `created`, `failed`, `manual`, `pending`,
  `preparing`, `running`, `scheduled`, `skipped`, `success`, `waiting_for_callback`,
  or `waiting_for_resource`
- `List` (use `in` operator for multiple values)

## Dimensions

| Dimension   | Name       | Description                              |
| ----------- | ---------- | ---------------------------------------- |
| Finished at | `finished` | Group by finish date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `daily`, `weekly`, or `monthly` (default: `weekly`). For example, `finished(daily)`. |
| Project     | `project`  | Group by project.                        |
| Ref         | `ref`      | Group by Git ref (branch or tag).        |
| Source      | `source`   | Group by what triggered the pipeline.    |
| Started at  | `started`  | Group by start date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `daily`, `weekly`, or `monthly` (default: `weekly`). For example, `started(daily)`. |
| Status      | `status`   | Group by pipeline status.                |

## Metrics

A pipeline is considered finished when it has completed processing and reached a final state: successful, failed, canceled, or skipped.

| Metric            | Name               | Description                                            |
| ----------------- | ------------------ | ------------------------------------------------------ |
| Canceled rate     | `canceledRate`     | Ratio of canceled pipelines to finished pipelines.    |
| Duration quantile | `durationQuantile` | Pipeline duration quantile, in seconds. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.95`). For example, `durationQuantile(0.5)`. |
| Failure rate      | `failureRate`      | Ratio of failed pipelines to finished pipelines.      |
| Skipped rate      | `skippedRate`      | Ratio of skipped pipelines to finished pipelines.     |
| Success rate      | `successRate`      | Ratio of successful pipelines to finished pipelines.  |
| Total count       | `totalCount`       | Total number of pipelines, including in-progress ones. |

## Sort fields

Sort by any field included in your selected dimensions or metrics. For more
information, see [analytics mode sorting](../_index.md#sorting).

## Examples

- Pipeline success and failure rates by ref for the last 30 days:

  ````yaml
  ```glql
  title: "Pipeline success and failure rates by branch (last 30 days)"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and finished >= -30d
  dimensions: ref as "Ref"
  metrics: totalCount as "Total", successRate as "Success rate", failureRate as "Failure rate"
  sort: totalCount desc
  ```
  ````

- Pipeline duration trend by week for a specific ref:

  ````yaml
  ```glql
  title: "Weekly pipeline duration trend for master"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and ref = "master" and finished >= -90d
  dimensions: finished as "Week"
  metrics: totalCount as "Total", durationQuantile as "p95 duration (s)"
  sort: finished desc
  ```
  ````

- Median and p95 pipeline duration by week:

  ````yaml
  ```glql
  title: "Median and p95 pipeline duration by week"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and finished >= -90d
  dimensions: finished(weekly) as "Week", status as "Status"
  metrics: durationQuantile(0.5) as "Median", durationQuantile(0.95) as "p95", totalCount as "Total"
  sort: Median desc
  ```
  ````

- Overall pipeline metrics for a group, without grouping:

  ````yaml
  ```glql
  title: "Overall pipeline metrics for gitlab-org"
  display: table
  mode: analytics
  query: type = Pipeline and group = "gitlab-org" and finished >= -7d
  metrics: totalCount as "Total", successRate as "Success rate", failureRate as "Failure rate", canceledRate as "Canceled rate"
  ```
  ````

- Pipelines grouped by source and status, filtered to a date range:

  ````yaml
  ```glql
  title: "Pipelines by source and status (Q1 2026)"
  display: table
  mode: analytics
  query: type = Pipeline and project = "gitlab-org/gitlab" and finished >= "2026-01-01" and finished <= "2026-03-31"
  dimensions: source as "Source", status as "Status"
  metrics: totalCount as "Total"
  sort: totalCount desc
  ```
  ````

- Filter to specific refs and statuses across a group:

  ````yaml
  ```glql
  title: "Default branch pipeline outcomes across gitlab-org"
  display: table
  mode: analytics
  query: type = Pipeline and group = "gitlab-org" and finished >= -14d and ref in ("master", "main") and status in ("success", "failed")
  dimensions: project as "Project", status as "Status"
  metrics: totalCount as "Total", successRate as "Success rate"
  sort: totalCount desc
  limit: 20
  ```
  ````
