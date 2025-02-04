---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Metrics Dictionary Guide
---

[Service Ping](../service_ping/_index.md) metrics are defined in individual YAML files definitions from which the
[Metrics Dictionary](https://metrics.gitlab.com/) is built. Currently, the metrics dictionary is built automatically once an hour.

- When a change to a metric is made in a YAML file, you can see the change in the dictionary within 1 hour of the change getting deployed to production.
- When a change to an event is made in a YAML file, you can see the change in the dictionary within 1 hour of the change getting merged to the master branch.

This guide describes the dictionary and how it's implemented.

## Metrics Definition and validation

We are using [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json) to validate the metrics definition.

This process is meant to ensure consistent and valid metrics defined for Service Ping. All metrics *must*:

- Comply with the defined [JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Have a unique `key_path` .
- Have an owner.

We currently have `tier` as one of the required fields for a metric definition file, however, we are now moving towards replacing `tier` with `tiers`, for this purpose it is valid to add `tiers` as a field in the metric definition files. Until the replacement process is complete, both `tier` and `tiers` would be valid fields that can be added to the metric definition files.

All metrics are stored in YAML files:

- [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics)

WARNING:
Only metrics with a metric definition YAML and whose status is not `removed` are added to the Service Ping JSON payload.

Each metric is defined in a YAML file consisting of a number of fields:

| Field                        | Required | Additional information |
|------------------------------|----------|------------------------|
| `key_path`                   | yes      | JSON key path for the metric, location in Service Ping payload. |
| `description`                | yes      |                        |
| `product_group`              | yes      | The [group](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) that owns the metric. |
| `value_type`                 | yes      | `string`; one of [`string`, `number`, `boolean`, `object`](https://json-schema.org/understanding-json-schema/reference/type). |
| `status`                     | yes      | `string`; [status](#metric-statuses) of the metric, may be set to `active`, `removed`, `broken`. |
| `time_frame`                 | yes      | `string` or `array`; may be set to `7d`, `28d`, `all`, `none` or an array including any of these values except for `none`. |
| `data_source`                | yes      | `string`; may be set to a value like `database`, `redis`, `redis_hll`, `prometheus`, `system`, `license`, `internal_events`. |
| `data_category`              | yes      | `string`; [categories](#data-category) of the metric, may be set to `operational`, `optional`, `subscription`, `standard`. The default value is `optional`. |
| `instrumentation_class`      | no       | `string`; used for metrics with `data_source` other than `internal_events`. See [the class that implements the metric](metrics_instrumentation.md). |
| `performance_indicator_type` | no       | `array`; may be set to one of [`gmau`, `smau`, `paid_gmau`, `umau`, `customer_health_score`, `devops_report`, `lighthouse`, or `leading_indicator`](https://handbook.gitlab.com/handbook/business-technology/data-team/data-catalog/). |
| `tier`                       | yes      | `array`; may contain one or a combination of `free`, `premium` or `ultimate`. The [tier](https://handbook.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available. This should be verbose and contain all tiers where a metric is available. |
| `tiers`                       | no      | `array`; may contain one or a combination of `free`, `premium` or `ultimate`. The [tiers](https://handbook.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available. This should be verbose and contain all tiers where a metric is available. |
| `milestone`                  | yes      | The milestone when the metric is introduced and when it's available to self-managed instances with the official GitLab release. |
| `milestone_removed`          | no       | The milestone when the metric is removed. Required for removed metrics. |
| `introduced_by_url`          | yes      | The URL to the merge request that introduced the metric to be available for self-managed instances. |
| `removed_by_url`             | no       | The URL to the merge request that removed the metric. Required for removed metrics. |
| `repair_issue_url`           | no       | The URL of the issue that was created to repair a metric with a `broken` status. |
| `options`                    | no       | `object`: options information needed to calculate the metric value. |

### Metric `key_path`

The `key_path` of the metric is the location in the JSON Service Ping payload.

The `key_path` could be composed from multiple parts separated by `.` and it must be unique.

If a metric definition has an array `time_frame`, the `key_path` defined in the YAML file will have a suffix automatically added for each of the included time frames:

| time_frame | `key_path` suffix|
|------------|------------------|
| `all`      | no suffix |
| `7d`       | `_weekly` |
| `28d`      | `_monthly` |

The `key_path`s shown in the [Metrics Dictionary](https://metrics.gitlab.com/) include those suffixes.

### Metric statuses

Metric definitions can have one of the following statuses:

- `active`: Metric is used and reports data.
- `broken`: Metric reports broken data (for example, -1 fallback), or does not report data at all. A metric marked as `broken` must also have the `repair_issue_url` attribute.
- `removed`: Metric was removed, but it may appear in Service Ping payloads sent from instances running on older versions of GitLab.

### Metric `value_type`

Metric definitions can have one of the following values for `value_type`:

- `boolean`
- `number`
- `string`
- `object`: A metric with `value_type: object` must have `value_json_schema` with a link to the JSON schema for the object.
  In general, we avoid complex objects and prefer one of the `boolean`, `number`, or `string` value types.
  An example of a metric that uses `value_type: object` is `topology` (`/config/metrics/settings/20210323120839_topology.yml`),
  which has a related schema in `/config/metrics/objects_schemas/topology_schema.json`.

### Metric `time_frame`

A metric's time frame is calculated based on the `time_frame` field and the `data_source` of the metric. When `time_frame` is an array, the metric's values are calculated for each of the included time frames.

| data_source            | time_frame | Description                                     |
|------------------------|------------|-------------------------------------------------|
| any                    | `none`     | A type of data that's not tracked over time, such as settings and configuration information |
| `database`             | `all`      | The whole time the metric has been active (all-time interval) |
| `database`             | `7d`       | 9 days ago to 2 days ago |
| `database`             | `28d`      | 30 days ago to 2 days ago |
| `internal_events`      | `all`      | The whole time the metric has been active (all-time interval) |
| `internal_events`      | `7d`       | Most recent complete week |
| `internal_events`      | `28d`      | Most recent 4 complete weeks |

### Data category

We use the following categories to classify a metric:

- `operational`: Required data for operational purposes.
- `optional`: Default value for a metric. Data that is optional to collect. This can be [enabled or disabled](../../../administration/settings/usage_statistics.md#enable-or-disable-service-ping) in the **Admin** area.
- `subscription`: Data related to licensing.
- `standard`: Standard set of identifiers that are included when collecting data.

### Example YAML metric definition

The linked [`uuid`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/license/uuid.yml)
YAML file includes an example metric definition, where the `uuid` metric is the GitLab
instance unique identifier.

```yaml
key_path: uuid
description: GitLab instance unique identifier
product_group: analytics_instrumentation
value_type: string
status: active
milestone: 9.1
instrumentation_class: UuidMetric
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1521
time_frame: none
data_source: database
tier:
- free
- premium
- ultimate
tiers:
- free
- premium
- ultimate
```

### Create a new metric definition

The GitLab codebase provides dedicated generators to create new metrics, which also create valid metric definition files:

- [internal events generator](../internal_event_instrumentation/quick_start.md)
- [metric instrumentation class generator](metrics_instrumentation.md#create-a-new-metric-instrumentation-class)

For uniqueness, the generated files include a timestamp prefix in ISO 8601 format.

### Performance Indicator Metrics

To use a metric definition to manage [performance indicator](https://handbook.gitlab.com/handbook/product/analytics-instrumentation-guide/#instrumenting-metrics-and-events):

1. Create a merge request that includes related changes.
1. Use labels `~"analytics instrumentation"`, `"~Data Warehouse::Impact Check"`.
1. Update the metric definition `performance_indicator_type` [field](metrics_dictionary.md#metrics-definition-and-validation).
1. Create an issue in GitLab Product Data Insights project with the [PI Chart Help template](https://gitlab.com/gitlab-data/product-analytics/-/issues/new?issuable_template=PI%20Chart%20Help) to have the new metric visualized.

## Metrics Dictionary

[Metrics Dictionary is a separate application](https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/metric-dictionary).

All metrics available in Service Ping are in the [Metrics Dictionary](https://metrics.gitlab.com/).
