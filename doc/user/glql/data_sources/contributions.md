---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Contributions
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21212) in GitLab 19.2.
- Configurable `granularity` parameter [introduced](https://gitlab.com/gitlab-org/glql/-/issues/130) in GitLab 19.3.

{{< /history >}}

Contributions is a data source that provides aggregated metrics about
contribution activity (such as commits, issues, and merge requests) across
your projects or groups.

## Allowed modes

- [`analytics`](../_index.md#analytics-mode)

## Allowed scopes

| Scope     | Description                                                              |
| --------- | ------------------------------------------------------------------------ |
| `project` | Query contributions in a specific project.                               |
| `group`   | Query contributions across all projects in a group, including subgroups. |

## Query fields

Use these fields in the `query` parameter to filter your results.

| Field                      | Name      | Operators                 |
| -------------------------- | --------- | ------------------------- |
| [Created at](#created-at)  | `created` | `=`, `>`, `<`, `>=`, `<=` |
| [User](#user)              | `user`    | `=`, `in`                 |

### Created at {#created-at}

**Description**: Filter contributions by date when they were created.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, GLQL considers the time range from 00:00 to 23:59 in the user's time zone.

### User {#user}

**Description**: Filter by the user who made the contributions.

**Allowed value types**:

- `Number` (user ID)
- `List` (use `in` operator for multiple user IDs)

> [!note]
> Support for username filtering is being tracked in [GLQL issue 143](https://gitlab.com/gitlab-org/glql/-/work_items/143).

## Dimensions

| Dimension  | Name      | Description                                          |
| ---------- | --------- | ----------------------------------------------------- |
| Created at | `created` | Group by contribution creation date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `daily`, `weekly`, or `monthly` (default: `monthly`). For example, `created(weekly)`. |

## Metrics

| Metric      | Name         | Description                    |
| ----------- | ------------ | ------------------------------- |
| Total count | `totalCount` | Total number of contributions. |
| Users count | `usersCount` | Number of unique contributors. |

## Sort fields

Sort by any field included in your selected dimensions or metrics. For more
information, see [analytics mode sorting](../_index.md#sorting).

## Examples

- Monthly contribution trend for a project:

  ````yaml
  ```glql
  title: "Monthly contributions"
  display: table
  mode: analytics
  query: type = Contribution and project = "gitlab-org/gitlab"
  dimensions: created as "Month"
  metrics: totalCount as "Total", usersCount as "Contributors"
  sort: created desc
  ```
  ````

- Contribution trend for a set of users:

  ````yaml
  ```glql
  title: "Contributions from a set of users"
  display: table
  mode: analytics
  query: type = Contribution and project = "gitlab-org/gitlab" and user in (1234567, 2345678) and created >= -90d
  dimensions: created as "Month"
  metrics: totalCount as "Total"
  sort: created desc
  ```
  ````

- A specific user's contributions over the last year, by month:

  ````yaml
  ```glql
  title: "User contribution history"
  display: table
  mode: analytics
  query: type = Contribution and group = "gitlab-org" and user = 1234567 and created >= -365d
  dimensions: created as "Month"
  metrics: totalCount as "Total"
  sort: created asc
  ```
  ````

- Overall contribution metrics for a group, without grouping:

  ````yaml
  ```glql
  title: "Overall contribution metrics"
  display: table
  mode: analytics
  query: type = Contribution and group = "gitlab-org" and created >= -90d
  metrics: totalCount as "Total", usersCount as "Contributors"
  ```
  ````
