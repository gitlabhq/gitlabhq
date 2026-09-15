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

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/606576) in GitLab 19.4 as an [experiment](../../../policy/development_stages_support.md#experiment).

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

For more information, see [scopes](_index.md#scopes).

## Query fields

Use these fields in the `query` parameter to filter your results.

| Field                   | Name (and alias)                              | Operators                 |
| ----------------------- | --------------------------------------------- | ------------------------- |
| [Created](#created)     | `created` (`opened`, `openedAt`, `createdAt`) | `=`, `>`, `<`, `>=`, `<=` |
| [Flow type](#flow-type) | `flowType`                                    | `=`, `in`                 |
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
| Project   | `project`  | Group by project. Flows that are not scoped to a project are grouped into a single row with no project. |
| User      | `user`     | Group by user (displays avatar, name, and username). |

## Metrics

| Metric                | Name                  | Description |
|-----------------------|-----------------------|-------------|
| Credits used max      | `creditsUsedMax`      | Most credits used by a single flow. |
| Credits used mean     | `creditsUsedMean`     | Average credits used per flow. |
| Credits used min      | `creditsUsedMin`      | Fewest credits used by a single flow. |
| Credits used quantile | `creditsUsedQuantile` | Credits used per flow at a given quantile. Accepts a [`quantile` parameter](../_index.md#field-parameters) between `0.01` and `0.99` (default: `0.5`). For example, `creditsUsedQuantile(0.95)`. |
| Credits used sum      | `creditsUsedSum`      | Total credits used by all flows. |
| Projects count        | `projectsCount`       | Number of unique projects. Flows that are not scoped to a project are not counted, so the row for those flows shows `0`. |
| Total count           | `totalCount`          | Total number of flows. |
| Users count           | `usersCount`          | Number of unique users. |

> [!note]
> The credits metrics require the Owner or Security Manager role for the group or project, or a
> [custom role](../../custom_roles/abilities.md) with the `read_agent_artifacts` permission.
> For other users, these metrics are empty.

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
