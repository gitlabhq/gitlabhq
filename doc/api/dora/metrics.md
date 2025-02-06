---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# DevOps Research and Assessment (DORA) key metrics API

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can also retrieve [DORA metrics](../../user/analytics/dora_metrics.md) with the [GraphQL API](../graphql/reference/_index.md).

All methods require at least the Reporter role.

## Get project-level DORA metrics

Get project-level DORA metrics.

```plaintext
GET /projects/:id/dora/metrics
```

| Attribute            | Type             | Required | Description |
|:---------------------|:-----------------|:---------|:------------|
| `id`                 | integer/string   | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths) can be accessed by the authenticated user. |
| `metric`             | string           | yes      | One of `deployment_frequency`, `lead_time_for_changes`, `time_to_restore_service` or `change_failure_rate`. |
| `end_date`           | string           | no       | Date range to end at. ISO 8601 Date format, for example `2021-03-01`. Default is the current date. |
| `environment_tiers`  | array of strings | no       | The [tiers of the environments](../../ci/environments/_index.md#deployment-tier-of-environments). Default is `production`. |
| `interval`           | string           | no       | The bucketing interval. One of `all`, `monthly` or `daily`. Default is `daily`. |
| `start_date`         | string           | no       | Date range to start from. ISO 8601 Date format, for example `2021-03-01`. Default is 3 months ago. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/dora/metrics?metric=deployment_frequency"
```

Example response:

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## Get group-level DORA metrics

Get group-level DORA metrics.

```plaintext
GET /groups/:id/dora/metrics
```

| Attribute           | Type             | Required | Description |
|:--------------------|:-----------------|:---------|:------------|
| `id`                | integer/string   | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths) can be accessed by the authenticated user. |
| `metric`            | string           | yes      | One of `deployment_frequency`, `lead_time_for_changes`, `time_to_restore_service` or `change_failure_rate`. |
| `end_date`          | string           | no       | Date range to end at. ISO 8601 Date format, for example `2021-03-01`. Default is the current date. |
| `environment_tiers` | array of strings | no       | The [tiers of the environments](../../ci/environments/_index.md#deployment-tier-of-environments). Default is `production`. |
| `interval`          | string           | no       | The bucketing interval. One of `all`, `monthly` or `daily`. Default is `daily`. |
| `start_date`        | string           | no       | Date range to start from. ISO 8601 Date format, for example `2021-03-01`. Default is 3 months ago. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/dora/metrics?metric=deployment_frequency"
```

Example response:

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## The `value` field

For both the project and group-level endpoints above, the `value` field in the
API response has a different meaning depending on the provided `metric` query
parameter:

| `metric` query parameter   | Description of `value` in response |
|:---------------------------|:-----------------------------------|
| `deployment_frequency`     | The API returns the total number of successful deployments during the time period. [Issue 371271](https://gitlab.com/gitlab-org/gitlab/-/issues/371271) proposes to update the API to return the daily average instead of the total number. |
| `change_failure_rate`      | The number of incidents divided by the number of deployments during the time period. Available only for production environment. |
| `lead_time_for_changes`    | The median number of seconds between the merge of the merge request (MR) and the deployment of the MR commits for all MRs deployed during the time period. |
| `time_to_restore_service`  | The median number of seconds an incident was open during the time period. Available only for production environment. |

NOTE:
The API returns the `monthly` and `all` intervals by calculating the median of the daily median values. This can introduce a slight inaccuracy in the returned data.
