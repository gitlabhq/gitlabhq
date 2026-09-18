---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Duo workflows
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/606576) in GitLab 19.5 as an [experiment](../../../policy/development_stages_support.md#experiment).
- `model` dimension [introduced](https://gitlab.com/gitlab-org/glql/-/merge_requests/511) in GitLab 19.5.
- `status` filter and dimension, and the `flowTypesCount`, `returningUsersCount`, `joinedUsersCount`, `churnedUsersCount`, `previousPeriodUsersCount`, `createdMrCount`, `mergedMrCount`, and `closedMrCount` metrics [introduced](https://gitlab.com/gitlab-org/glql/-/merge_requests/514) in GitLab 19.5.

{{< /history >}}

> [!flag]
> This data source reads from the GitLab Duo Agent Platform flow analytics engine, which is
> controlled by a [feature flag](../../../administration/feature_flags/_index.md) named `dap_impact_v1`.
> The flag is disabled by default. Until an administrator enables it, queries return an error.

This data source provides aggregated metrics about GitLab Duo Agent Platform flows
(also called Duo workflows) run across your project or group, including how many
credits they used.

## Allowed modes

- [`analytics`](../_index.md#analytics-mode)

## Allowed scopes

| Scope     | Description |
|-----------|-------------|
| `project` | Query GitLab Duo Agent Platform flows in a specific project. |
| `group`   | Query GitLab Duo Agent Platform flows across all projects in a group, including subgroups. |

To aggregate GitLab Duo workflows across multiple groups or projects, use a list with the `in` operator.
For more information, see [multiple groups and projects](_index.md#multiple-groups-and-projects).

## Query fields

Use these fields in the `query` parameter to filter your results.

| Field                   | Name (and alias)                              | Operators                 |
| ----------------------- | --------------------------------------------- | ------------------------- |
| [Created](#created)     | `created` (`opened`, `openedAt`, `createdAt`) | `=`, `>`, `<`, `>=`, `<=` |
| [Flow type](#flow-type) | `flowType`                                    | `=`, `in`                 |
| [Status](#status)       | `status`                                      | `=`, `in`                 |
| [User](#user)           | `user`                                        | `=`, `in`                 |

### Created

**Description**: Filter flows by date they were created.
Use multiple `created` conditions to define a specified time period.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months), or `y` (years))

**Notes**:

- For the `=` operator, GLQL considers the time range from 00:00 to 23:59 in the user's time zone.

### Flow type

**Description**: Filter flows by their type.
For example, `software_development` or `code_review/v1`.

**Allowed value types**:

- `String`
- `List` (use `in` operator for multiple values)

### Status

**Description**: Filter flows by their lifecycle status.

**Allowed value types**:

- `Enum`, one of `created`, `running`, `paused`, `finished`, `failed`, `stopped`,
  `input_required`, `plan_approval_required`, or `tool_call_approval_required`
- `List` (use `in` operator for multiple values)

**Notes**:

- The three `*_required` statuses are flows waiting on the user, and are distinct from `paused`.
- Statuses are matched case-insensitively. Other spellings, like `completed` or `aborted`, are not accepted.

### User

**Description**: Filter by the user who ran the flow.

**Allowed value types**:

- `Number` (user ID)
- `List` (use `in` operator for multiple user IDs)

> [!note]
> Support for username filtering is being tracked in [issue 599750](https://gitlab.com/gitlab-org/gitlab/-/work_items/599750).

## Dimensions

| Dimension | Name       | Description |
|-----------|------------|-------------|
| Created   | `created`  | Group by date. Accepts a [`granularity` parameter](../_index.md#field-parameters) of `daily`, `weekly`, or `monthly` (default: `monthly`). For example, `created(weekly)`. |
| Flow type | `flowType` | Group by flow type. |
| Model     | `model`    | Group by the model the flow used. |
| Project   | `project`  | Group by project. Flows that are not scoped to a project are grouped into a single row with no project. |
| Status    | `status`   | Group by flow status. Rows are sorted in lifecycle order, not alphabetically. |
| User      | `user`     | Group by user (displays avatar, name, and username). |

## Metrics

| Metric                      | Name                       | Description |
|-----------------------------|----------------------------|-------------|
| Churned users count         | `churnedUsersCount`        | Number of unique users who ran a flow in the previous period but not in this one. |
| Closed MR count max         | `closedMrCountMax`         | Most closed merge requests created by a single flow. |
| Closed MR count mean        | `closedMrCountMean`        | Average closed merge requests created per flow. |
| Closed MR count min         | `closedMrCountMin`         | Fewest closed merge requests created by a single flow. |
| Closed MR count quantile    | `closedMrCountQuantile`    | Closed merge requests created per flow at a given quantile. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.5`). For example, `closedMrCountQuantile(0.95)`. |
| Closed MR count sum         | `closedMrCountSum`         | Total closed merge requests created by all flows. |
| Created MR count max        | `createdMrCountMax`        | Most merge requests created by a single flow. |
| Created MR count mean       | `createdMrCountMean`       | Average merge requests created per flow. |
| Created MR count min        | `createdMrCountMin`        | Fewest merge requests created by a single flow. |
| Created MR count quantile   | `createdMrCountQuantile`   | Merge requests created per flow at a given quantile. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.5`). For example, `createdMrCountQuantile(0.95)`. |
| Created MR count sum        | `createdMrCountSum`        | Total merge requests created by all flows. |
| Credits used max            | `creditsUsedMax`           | Most credits used by a single flow. |
| Credits used mean           | `creditsUsedMean`          | Average credits used per flow. |
| Credits used min            | `creditsUsedMin`           | Fewest credits used by a single flow. |
| Credits used quantile       | `creditsUsedQuantile`      | Credits used per flow at a given quantile. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.5`). For example, `creditsUsedQuantile(0.95)`. |
| Credits used sum            | `creditsUsedSum`           | Total credits used by all flows. |
| Flow types count            | `flowTypesCount`           | Number of unique flow types. |
| Joined users count          | `joinedUsersCount`         | Number of unique users who ran a flow in this period but not in the previous one. |
| Merged MR count max         | `mergedMrCountMax`         | Most merged merge requests created by a single flow. |
| Merged MR count mean        | `mergedMrCountMean`        | Average merged merge requests created per flow. |
| Merged MR count min         | `mergedMrCountMin`         | Fewest merged merge requests created by a single flow. |
| Merged MR count quantile    | `mergedMrCountQuantile`    | Merged merge requests created per flow at a given quantile. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.5`). For example, `mergedMrCountQuantile(0.95)`. |
| Merged MR count sum         | `mergedMrCountSum`         | Total merged merge requests created by all flows. |
| Previous period users count | `previousPeriodUsersCount` | Number of unique users in the previous period. |
| Projects count              | `projectsCount`            | Number of unique projects. Flows that are not scoped to a project are not counted, so the row for those flows shows `0`. |
| Returning users count       | `returningUsersCount`      | Number of unique users who also ran a flow in the previous period. |
| Total count                 | `totalCount`               | Total number of flows. |
| Users count                 | `usersCount`               | Number of unique users. |

> [!note]
> The credits metrics require the Owner or Security Manager role for the group or project, or a
> [custom role](../../custom_roles/abilities.md) with the `read_agent_artifacts` permission.
> For other users, these metrics are empty.

**Notes**:

- The `returningUsersCount`, `joinedUsersCount`, `churnedUsersCount`, and `previousPeriodUsersCount`
  metrics compare each `created` bucket with the preceding one, so they are only valid when the
  `created` dimension is also selected. A `created` filter alone is not enough.
- The `mergedMrCount` and `closedMrCount` metrics count merge requests a flow created that were
  later merged, or closed without merging. They can lag behind the current state of those merge requests.

## Sort fields

Sort by any field included in your selected dimensions or metrics. For more
information, see [analytics mode sorting](../_index.md#sorting).

## Examples

- Flows by flow type for the last 30 days:

  ````yaml
  ```glql
  title: "Duo workflows by flow type (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: flowType as "Flow"
  metrics: totalCount as "Flows", usersCount as "Users", creditsUsedSum as "Credits"
  sort: totalCount desc
  ```
  ````

- Monthly credit usage trend:

  ````yaml
  ```glql
  title: "Monthly Duo workflow credit usage trend"
  display: columnChart
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d
  dimensions: created(monthly) as "Month"
  metrics: creditsUsedSum as "Credits used"
  sort: created asc
  ```
  ````

- Top users by credits for the last 30 days:

  ````yaml
  ```glql
  title: "Top users by Duo workflow credits (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: user as "User"
  metrics: totalCount as "Flows", creditsUsedSum as "Credits", creditsUsedMean as "Avg credits per flow"
  sort: creditsUsedSum desc
  limit: 10
  ```
  ````

- Flows by status for the last 30 days:

  ````yaml
  ```glql
  title: "Duo workflows by status (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  dimensions: status as "Status"
  metrics: totalCount as "Flows", createdMrCountSum as "MRs created", mergedMrCountSum as "MRs merged"
  sort: status asc
  ```
  ````

- Weekly user retention:

  ````yaml
  ```glql
  title: "Weekly Duo workflow user retention"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -90d
  dimensions: created(weekly) as "Week"
  metrics: usersCount as "Users", returningUsersCount as "Returning", joinedUsersCount as "Joined", churnedUsersCount as "Churned"
  sort: created desc
  ```
  ````

- Overall usage without grouping:

  ````yaml
  ```glql
  title: "Duo workflow usage overview (last 30 days)"
  display: table
  mode: analytics
  query: type = DuoWorkflow and group = "gitlab-org" and created > -30d
  metrics: totalCount as "Flows", usersCount as "Users", projectsCount as "Projects", creditsUsedQuantile(0.5) as "Median credits"
  ```
  ````
