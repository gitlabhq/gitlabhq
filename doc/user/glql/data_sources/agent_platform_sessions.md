---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agent platform sessions
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/592423) in GitLab 19.4.

{{< /history >}}

This data source provides aggregated metrics about GitLab Duo Agent Platform
session usage across your project or group.

## Allowed modes

- [`analytics`](../_index.md#analytics-mode)

## Allowed scopes

| Scope     | Description |
|-----------|-------------|
| `project` | Query GitLab Duo Agent Platform sessions in a specific project. |
| `group`   | Query GitLab Duo Agent Platform sessions across all projects in a group, including subgroups. |

For more information, see [scopes](_index.md#scopes).

## Query fields

Use these fields in the `query` parameter to filter your results.

| Field                   | Name (and alias)                                | Operators                 |
| ----------------------- | ----------------------------------------------- | ------------------------- |
| [Created](#created)     | `created` (`opened`, `openedAt`, `createdAt`)   | `=`, `>`, `<`, `>=`, `<=` |
| [Flow type](#flow-type) | `flowType`                                      | `=`, `in`                 |
| [User](#user)           | `user`                                          | `=`, `in`                 |

### Created

**Description**: Filter by when the session was created.
Use range operators to define a time window.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months), or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.

### Flow type

**Description**: Filter by the flow type of the session. For example,
`chat` or `code_review/v1`.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### User

**Description**: Filter by the user who owns the session.

**Allowed value types**:

- `Number` (user ID)
- `List` (use `in` operator for multiple user IDs)

> [!note]
> Support for username filtering is being tracked in [issue 599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750).

## Dimensions

| Dimension | Name       | Description |
|-----------|------------|-------------|
| Created   | `created`  | Group by date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `weekly` or `monthly` (default: `weekly`). For example, `created(monthly)`. |
| Flow type | `flowType` | Group by session flow type. |
| Project   | `project`  | Group by project. Sessions that are not scoped to a project are grouped into a single row with no project. |
| User      | `user`     | Group by user (displays avatar, name, and username). |

## Metrics

| Metric            | Name               | Description |
|-------------------|--------------------|-------------|
| Completion rate   | `completionRate`   | Proportion of sessions that finished, as a value from 0 to 1. |
| Duration max      | `durationMax`      | Longest finished session duration, in seconds. |
| Duration mean     | `durationMean`     | Average duration of finished sessions, in seconds. |
| Duration min      | `durationMin`      | Shortest finished session duration, in seconds. |
| Duration quantile | `durationQuantile` | Duration of finished sessions at a given quantile, in seconds. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.5`). For example, `durationQuantile(0.95)`. |
| Duration sum      | `durationSum`      | Total duration of finished sessions, in seconds. |
| Finished count    | `finishedCount`    | Number of finished sessions. |
| Total count       | `totalCount`       | Total number of sessions. |
| Users count       | `usersCount`       | Number of unique users. |

## Sort fields

Sort by any dimension, or by one of these metrics:

- `totalCount`
- `finishedCount`
- `usersCount`
- `completionRate`
- `durationQuantile`.

These metrics are not sortable:

- `durationMean`
- `durationMin`
- `durationMax`
- `durationSum`

For more information, see [analytics mode sorting](../_index.md#sorting).

## Examples

- Sessions by flow type for the last 30 days:

  ````yaml
  ```glql
  title: "Agent Platform sessions by flow (last 30 days)"
  display: table
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -30d
  dimensions: flowType as "Flow"
  metrics: totalCount as "Total", finishedCount as "Finished", completionRate as "Completion rate"
  sort: totalCount desc
  ```
  ````

- Weekly session trend:

  ````yaml
  ```glql
  title: "Weekly Agent Platform session trend"
  display: columnChart
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -90d
  dimensions: created(weekly) as "Week"
  metrics: totalCount as "Total", usersCount as "Users"
  sort: created desc
  ```
  ````

- Sessions per user, with average duration:

  ````yaml
  ```glql
  title: "Agent Platform sessions by user"
  display: table
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -30d
  dimensions: user as "User"
  metrics: totalCount as "Total", durationMean as "Avg duration"
  sort: totalCount desc
  limit: 10
  ```
  ````

- Overall completion rate and median duration, without grouping:

  ````yaml
  ```glql
  title: "Agent Platform session completion (last 30 days)"
  display: table
  mode: analytics
  query: type = AgentPlatformSession and group = "gitlab-org" and created > -30d
  metrics: totalCount as "Total", completionRate as "Completion rate", durationQuantile(0.5) as "Median duration"
  ```
  ````
