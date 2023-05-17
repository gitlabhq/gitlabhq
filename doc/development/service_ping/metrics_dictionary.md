---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Metrics Dictionary Guide

[Service Ping](index.md) metrics are defined in individual YAML files definitions from which the
[Metrics Dictionary](https://metrics.gitlab.com/) is built. Currently, the metrics dictionary is built automatically once a day. When a change to a metric is made in a YAML file, you can see the change in the dictionary within 24 hours.
This guide describes the dictionary and how it's implemented.

## Metrics Definition and validation

We are using [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json) to validate the metrics definition.

This process is meant to ensure consistent and valid metrics defined for Service Ping. All metrics *must*:

- Comply with the defined [JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Have a unique `key_path` .
- Have an owner.

All metrics are stored in YAML files:

- [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics)

WARNING:
Only metrics with a metric definition YAML and whose status is not `removed` are added to the Service Ping JSON payload.

Each metric is defined in a separate YAML file consisting of a number of fields:

| Field               | Required | Additional information                                         |
|---------------------|----------|----------------------------------------------------------------|
| `key_path`          | yes      | JSON key path for the metric, location in Service Ping payload.  |
| `name`              | no       | Metric name suggestion. Can replace the last part of `key_path`. |
| `description`       | yes      |                                                                |
| `product_section`   | yes      | The [section](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/sections.yml). |
| `product_stage`     | yes       | The [stage](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) for the metric. |
| `product_group`     | yes      | The [group](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) that owns the metric. |
| `value_type`        | yes      | `string`; one of [`string`, `number`, `boolean`, `object`](https://json-schema.org/understanding-json-schema/reference/type.html).                                                     |
| `status`            | yes      | `string`; [status](#metric-statuses) of the metric, may be set to `active`, `removed`, `broken`. |
| `time_frame`        | yes      | `string`; may be set to a value like `7d`, `28d`, `all`, `none`. |
| `data_source`       | yes      | `string`; may be set to a value like `database`, `redis`, `redis_hll`, `prometheus`, `system`, `license`. |
| `data_category`     | yes      | `string`; [categories](#data-category) of the metric, may be set to `operational`, `optional`, `subscription`, `standard`. The default value is `optional`.|
| `instrumentation_class` | yes   | `string`; [the class that implements the metric](metrics_instrumentation.md).  |
| `distribution`      | yes      | `array`; may be set to one of `ce, ee` or `ee`. The [distribution](https://about.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available.  |
| `performance_indicator_type`  | no      | `array`; may be set to one of [`gmau`, `smau`, `paid_gmau`, `umau` or `customer_health_score`](https://about.gitlab.com/handbook/business-technology/data-team/data-catalog/xmau-analysis/). |
| `tier`              | yes      | `array`; may contain one or a combination of `free`, `premium` or `ultimate`. The [tier](https://about.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available. This should be verbose and contain all tiers where a metric is available. |
| `milestone`         | yes       | The milestone when the metric is introduced and when it's available to self-managed instances with the official GitLab release. |
| `milestone_removed` | no       | The milestone when the metric is removed. |
| `introduced_by_url` | no       | The URL to the merge request that introduced the metric to be available for self-managed instances. |
| `removed_by_url`    | no       | The URL to the merge request that removed the metric. |
| `repair_issue_url`  | no       | The URL of the issue that was created to repair a metric with a `broken` status. |
| `options`           | no       | `object`: options information needed to calculate the metric value. |
| `skip_validation`   | no       | This should **not** be set. [Used for imported metrics until we review, update and make them valid](https://gitlab.com/groups/gitlab-org/-/epics/5425). |

### Metric `key_path`

The `key_path` of the metric is the location in the JSON Service Ping payload.

The `key_path` could be composed from multiple parts separated by `.` and it must be unique.

We recommend to add the metric in one of the top-level keys:

- `settings`: for settings related metrics.
- `counts_weekly`: for counters that have data for the most recent 7 days.
- `counts_monthly`: for counters that have data for the most recent 28 days.
- `counts`: for counters that have data for all time.

NOTE:
We can't control what the metric's `key_path` is, because some of them are generated dynamically in `usage_data.rb`.
For example, see [Redis HLL metrics](implement.md#redis-hll-counters).

### Metric name

To improve metric discoverability by a wider audience, each metric with
instrumentation added at an appointed `key_path` receives a `name` attribute
filled with the name suggestion, corresponding to the metric `data_source` and instrumentation.
Metric name suggestions can contain two types of elements:

1. **User input prompts**: enclosed by angle brackets (`< >`), these pieces should be replaced or
   removed when you create a metrics YAML file.
1. **Fixed suggestion**: plaintext parts generated according to well-defined algorithms.
   They are based on underlying instrumentation, and must not be changed.

For a metric name to be valid, it must not include any prompt, and fixed suggestions
must not be changed.

#### Generate a metric name suggestion

The metric YAML generator can suggest a metric name for you.
To generate a metric name suggestion, first instrument the metric at the provided `key_path`.
Then, generate the metric's YAML definition and
return to the instrumentation and update it.

1. Add the metric instrumentation class to `lib/gitlab/usage/metrics/instrumentations/`.
1. Add the metric logic in the instrumentation class.
1. Run the [metrics YAML generator](metrics_dictionary.md#create-a-new-metric-definition).
1. Use the metric name suggestion to select a suitable metric name.
1. Update the metric's YAML definition with the correct `key_path`.

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

A metric's time frame is calculated based on the `time_frame` field and the `data_source` of the metric.
For `redis_hll` metrics, the type of aggregation is also taken into consideration. In this context, the term "aggregation" refers to [chosen events data storage interval](implement.md#add-new-events), and is **NOT** related to the Aggregated Metrics feature.
For more information about the aggregation type of each feature, see the [`common.yml` file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage_data_counters/known_events/common.yml). Weeks run from Monday to Sunday.

| data_source            | time_frame | aggregation    | Description                                     |
|------------------------|------------|----------------|-------------------------------------------------|
| any                    | `none`     | not applicable | A type of data that’s not tracked over time, such as settings and configuration information |
| `database`             | `all`      | not applicable | The whole time the metric has been active (all-time interval) |
| `database`             | `7d`       | not applicable | 9 days ago to 2 days ago |
| `database`             | `28d`      | not applicable | 30 days ago to 2 days ago |
| `redis`                | `all`      | not applicable | The whole time the metric has been active (all-time interval) |
| `redis_hll`            | `7d`       | `daily`        | Most recent 7 complete days |
| `redis_hll`            | `7d`       | `weekly`       | Most recent complete week |
| `redis_hll`            | `28d`      | `daily`        | Most recent 28 complete days |
| `redis_hll`            | `28d`      | `weekly`       | Most recent 4 complete weeks |

### Data category

We use the following categories to classify a metric:

- `operational`: Required data for operational purposes.
- `optional`: Default value for a metric. Data that is optional to collect. This can be [enabled or disabled](../../user/admin_area/settings/usage_statistics.md#enable-or-disable-usage-statistics) in the Admin Area.
- `subscription`: Data related to licensing.
- `standard`: Standard set of identifiers that are included when collecting data.

An aggregate metric is a metric that is the sum of two or more child metrics. Service Ping uses the data category of
the aggregate metric to determine whether or not the data is included in the reported Service Ping payload.

### Metric name suggestion examples

#### Metric with `data_source: database`

For a metric instrumented with SQL:

```sql
SELECT COUNT(DISTINCT user_id) FROM clusters WHERE clusters.management_project_id IS NOT NULL
```

- **Suggested name**: `count_distinct_user_id_from_<adjective describing: '(clusters.management_project_id IS NOT NULL)'>_clusters`
- **Prompt**: `<adjective describing: '(clusters.management_project_id IS NOT NULL)'>`
  should be replaced with an adjective that best represents filter conditions, such as `project_management`
- **Final metric name**: For example, `count_distinct_user_id_from_project_management_clusters`

For metric instrumented with SQL:

```sql
SELECT COUNT(DISTINCT clusters.user_id)
FROM clusters_applications_helm
INNER JOIN clusters ON clusters.id = clusters_applications_helm.cluster_id
WHERE clusters_applications_helm.status IN (3, 5)
```

- **Suggested name**: `count_distinct_user_id_from_<adjective describing: '(clusters_applications_helm.status IN (3, 5))'>_clusters_<with>_<adjective describing: '(clusters_applications_helm.status IN (3, 5))'>_clusters_applications_helm`
- **Prompt**: `<adjective describing: '(clusters_applications_helm.status IN (3, 5))'>`
  should be replaced with an adjective that best represents filter conditions
- **Final metric name**: `count_distinct_user_id_from_clusters_with_available_clusters_applications_helm`

In the previous example, the prompt is irrelevant, and user can remove it. The second
occurrence corresponds with the `available` scope defined in `Clusters::Concerns::ApplicationStatus`.
It can be used as the right adjective to replace prompt.

The `<with>` represents a suggested conjunction for the suggested name of the joined relation.
The person documenting the metric can use it by either:

- Removing the surrounding `<>`.
- Using a different conjunction, such as `having` or `including`.

#### Metric with `data_source: redis` or `redis_hll`

For metrics instrumented with a Redis-based counter, the suggested name includes
only the single prompt to be replaced by the person working with metrics YAML.

- **Prompt**: `<please fill metric name, suggested format is: {subject}_{verb}{ing|ed}_{object} eg: users_creating_epics or merge_requests_viewed_in_single_file_mode>`
- **Final metric name**: We suggest the metric name should follow the format of
  `{subject}_{verb}{ing|ed}_{object}`, such as `user_creating_epics`, `users_triggering_security_scans`,
  or `merge_requests_viewed_in_single_file_mode`

#### Metric with `data_source: prometheus` or `system`

For metrics instrumented with Prometheus or coming from the operating system,
the suggested name includes only the single prompt by person working with metrics YAML.

- **Prompt**: `<please fill metric name>`
- **Final metric name**: Due to the variety of cases that can apply to this kind of metric,
  no naming convention exists. Each person instrumenting a metric should use their
  best judgment to come up with a descriptive name.

### Example YAML metric definition

The linked [`uuid`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/license/uuid.yml)
YAML file includes an example metric definition, where the `uuid` metric is the GitLab
instance unique identifier.

```yaml
key_path: uuid
description: GitLab instance unique identifier
product_section: analytics
product_stage: analytics
product_group: product_intelligence
value_type: string
status: active
milestone: 9.1
instrumentation_class: UuidMetric
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1521
time_frame: none
data_source: database
distribution:
- ce
- ee
tier:
- free
- premium
- ultimate
```

### Create a new metric definition

The GitLab codebase provides a dedicated [generator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/generators/gitlab/usage_metric_definition_generator.rb) to create new metric definitions.

For uniqueness, the generated files include a timestamp prefix in ISO 8601 format.

The generator takes a list of key paths and 3 options as arguments. It creates metric YAML definitions in the corresponding location:

- `--ee`, `--no-ee` Indicates if metric is for EE.
- `--dir=DIR` Indicates the metric directory. It must be one of: `counts_7d`, `7d`, `counts_28d`, `28d`, `counts_all`, `all`, `settings`, `license`.
- `--class_name=CLASS_NAME` Indicates the instrumentation class. For example `UsersCreatingIssuesMetric`, `UuidMetric`

**Single metric example**

```shell
bundle exec rails generate gitlab:usage_metric_definition counts.issues --dir=7d --class_name=CountIssues
// Creates 1 file
// create  config/metrics/counts_7d/issues.yml
```

**Multiple metrics example**

```shell
bundle exec rails generate gitlab:usage_metric_definition counts.issues counts.users --dir=7d --class_name=CountUsersCreatingIssues
// Creates 2 files
// create  config/metrics/counts_7d/issues.yml
// create  config/metrics/counts_7d/users.yml
```

NOTE:
To create a metric definition used in EE, add the `--ee` flag.

```shell
bundle exec rails generate gitlab:usage_metric_definition counts.issues --ee --dir=7d --class_name=CountUsersCreatingIssues
// Creates 1 file
// create  ee/config/metrics/counts_7d/issues.yml
```

### Metrics added dynamic to Service Ping payload

The [Redis HLL metrics](implement.md#known-events-are-added-automatically-in-service-data-payload) are added automatically to Service Ping payload.

A YAML metric definition is required for each metric. A dedicated generator is provided to create metric definitions for Redis HLL events.

The generator takes `category` and `events` arguments, as the root key is `redis_hll_counters`, and creates two metric definitions for each of the events (for weekly and monthly time frames):

**Single metric example**

```shell
bundle exec rails generate gitlab:usage_metric_definition:redis_hll issues count_users_closing_issues
// Creates 2 files
// create  config/metrics/counts_7d/count_users_closing_issues_weekly.yml
// create  config/metrics/counts_28d/count_users_closing_issues_monthly.yml
```

**Multiple metrics example**

```shell
bundle exec rails generate gitlab:usage_metric_definition:redis_hll issues count_users_closing_issues count_users_reopening_issues
// Creates 4 files
// create  config/metrics/counts_7d/count_users_closing_issues_weekly.yml
// create  config/metrics/counts_28d/count_users_closing_issues_monthly.yml
// create  config/metrics/counts_7d/count_users_reopening_issues_weekly.yml
// create  config/metrics/counts_28d/count_users_reopening_issues_monthly.yml
```

To create a metric definition used in EE, add the `--ee` flag.

```shell
bundle exec rails generate gitlab:usage_metric_definition:redis_hll issues users_closing_issues --ee
// Creates 2 files
// create  config/metrics/counts_7d/i_closed_weekly.yml
// create  config/metrics/counts_28d/i_closed_monthly.yml
```

## Metrics Dictionary

[Metrics Dictionary is a separate application](https://gitlab.com/gitlab-org/analytics-section/product-intelligence/metric-dictionary).

All metrics available in Service Ping are in the [Metrics Dictionary](https://metrics.gitlab.com/).

### Copy query to clipboard

To check if a metric has data in Sisense, use the copy query to clipboard feature. This copies a query that's ready to use in Sisense. The query gets the last five service ping data for GitLab.com for a given metric. For information about how to check if a Service Ping metric has data in Sisense, see this [demo](https://www.youtube.com/watch?v=n4o65ivta48).
