---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI usage events
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21216) in GitLab 19.3.

{{< /history >}}

AI usage events is a data source that provides aggregated metrics about
GitLab Duo feature usage across your project or group.

## Allowed modes

- [`analytics`](../_index.md#analytics-mode)

## Allowed scopes

| Scope     | Description                                                                 |
| --------- | --------------------------------------------------------------------------- |
| `project` | Query AI usage events in a specific project.                                |
| `group`   | Query AI usage events across all projects in a group, including subgroups.  |

For more information, see [scopes](_index.md#scopes).

## Query fields

| Field                                | Name            | Operators                 |
| ------------------------------------ | --------------- | ------------------------- |
| [Event](#event)                      | `event`         | `=`, `in`                 |
| [Feature](#feature)                  | `feature`       | `=`, `in`                 |
| [Features count](#features-count)    | `featuresCount` | `>`, `<`, `>=`, `<=`      |
| [Timestamp](#timestamp)              | `timestamp`     | `=`, `>`, `<`, `>=`, `<=` |
| [User](#user)                        | `user`          | `=`, `in`                 |

### Event {#event}

**Description**: Filter by the event identifier.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### Feature {#feature}

**Description**: Filter by the GitLab Duo feature that generated the event. For example,
`code_suggestions` or `chat`.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### Features count {#features-count}

**Description**: Filter by the number of unique features used. This filter is only
valid when the `featuresCount` metric is also selected.

**Allowed value types**: `Number`

### Timestamp {#timestamp}

**Description**: Filter by when the event occurred.
Use range operators to define a time window.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.

### User {#user}

**Description**: Filter by the user who triggered the event.

**Allowed value types**:

- `Number` (user ID)
- `List` (use `in` operator for multiple user IDs)

> [!note]
> Support for username filtering is being tracked in [issue 599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750).

## Dimensions

| Dimension | Name        | Description                                          |
| --------- | ----------- | ---------------------------------------------------- |
| Event     | `event`     | Group by event identifier.                           |
| Feature   | `feature`   | Group by GitLab Duo feature.                         |
| Timestamp | `timestamp` | Group by date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `daily`, `weekly`, or `monthly` (default: `weekly`). For example, `timestamp(daily)`. |
| User      | `user`      | Group by user (displays avatar, name, and username). |

## Metrics

| Metric                      | Name                      | Description                                             |
| --------------------------- | ------------------------- | ------------------------------------------------------- |
| Features count              | `featuresCount`           | Number of unique features used.                         |
| Previous period users count | `previousPeriodUsersCount` | Number of unique users in the previous period.         |
| Returning users count       | `returningUsersCount`     | Number of users active in both the current and previous period. |
| Total count                 | `totalCount`              | Total number of events.                                 |
| Users count                 | `usersCount`              | Number of unique users.                                 |

**Notes**:

- The `returningUsersCount` and `previousPeriodUsersCount` metrics are only valid when the
  `timestamp` dimension is also selected.

## Sort fields

Sort by any field included in your selected dimensions or metrics. For more
information, see [analytics mode sorting](../_index.md#sorting).

## Examples

- Feature adoption for the last 30 days:

  ````yaml
  ```glql
  title: "GitLab Duo feature adoption (last 30 days)"
  display: table
  mode: analytics
  query: type = AiUsageEvent and group = "gitlab-org" and timestamp > -30d
  dimensions: feature as "Feature"
  metrics: totalCount as "Total events", usersCount as "Users"
  sort: usersCount desc
  ```
  ````

- Weekly usage trend with returning users:

  ````yaml
  ```glql
  title: "Weekly GitLab Duo usage trend"
  display: table
  mode: analytics
  query: type = AiUsageEvent and group = "gitlab-org" and timestamp > -30d
  dimensions: timestamp(weekly) as "Week"
  metrics: usersCount as "Users", returningUsersCount as "Returning users", previousPeriodUsersCount as "Previous period users"
  sort: timestamp desc
  ```
  ````

- Events per user for a specific project:

  ````yaml
  ```glql
  title: "GitLab Duo events by user"
  display: table
  mode: analytics
  query: type = AiUsageEvent and project = "gitlab-org/gitlab" and timestamp > -30d
  dimensions: user as "User"
  metrics: totalCount as "Total events"
  sort: totalCount desc
  limit: 10
  ```
  ````

- Overall unique users, without grouping:

  ````yaml
  ```glql
  title: "Unique GitLab Duo users (last 30 days)"
  display: table
  mode: analytics
  query: type = AiUsageEvent and group = "gitlab-org" and timestamp > -30d
  metrics: usersCount as "Users"
  ```
  ````
