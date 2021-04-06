---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Metrics Dictionary Guide

This guide describes Metrics Dictionary and how it's implemented

## Metrics Definition and validation

We are using [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json) to validate the metrics definition.

This process is meant to ensure consistent and valid metrics defined for Usage Ping. All metrics *must*:

- Comply with the defined [JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Have a unique `key_path` .
- Have an owner.

All metrics are stored in YAML files:

- [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics)

Each metric is defined in a separate YAML file consisting of a number of fields:

| Field               | Required | Additional information                                         |
|---------------------|----------|----------------------------------------------------------------|
| `key_path`          | yes      | JSON key path for the metric, location in Usage Ping payload.  |
| `description`       | yes      |                                                                |
| `product_section`   | yes      | The [section](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/sections.yml). |
| `product_stage`     | no       | The [stage](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) for the metric. |
| `product_group`     | yes      | The [group](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) that owns the metric. |
| `product_category`  | no       | The [product category](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml) for the metric. |
| `value_type`        | yes      | `string`; one of [`string`, `number`, `boolean`, `object`](https://json-schema.org/understanding-json-schema/reference/type.html).                                                     |
| `status`            | yes      | `string`; [status](#metric-statuses) of the metric, may be set to `data_available`, `implemented`, `not_used`, `deprecated`, `removed`. |
| `time_frame`        | yes      | `string`; may be set to a value like `7d`, `28d`, `all`, `none`. |
| `data_source`       | yes      | `string`; may be set to a value like `database`, `redis`, `redis_hll`, `prometheus`, `ruby`. |
| `distribution`      | yes      | `array`; may be set to one of `ce, ee` or `ee`. The [distribution](https://about.gitlab.com/handbook/marketing/strategic-marketing/tiers/#definitions) where the tracked feature is available.  |
| `tier`              | yes      | `array`; may be set to one of `free, premium, ultimate`, `premium, ultimate` or `ultimate`. The [tier]( https://about.gitlab.com/handbook/marketing/strategic-marketing/tiers/) where the tracked feature is available. |
| `milestone`         | no       | The milestone when the metric is introduced. |
| `milestone_removed` | no       | The milestone when the metric is removed. |
| `introduced_by_url` | no       | The URL to the Merge Request that introduced the metric. |
| `skip_validation`   | no       | This should **not** be set. [Used for imported metrics until we review, update and make them valid](https://gitlab.com/groups/gitlab-org/-/epics/5425). |

### Metric statuses

Metric definitions can have one of the following statuses:

- `data_available`: Metric data is available and used in a Sisense dashboard.
- `implemented`: Metric is implemented but data is not yet available. This is a temporary
  status for newly added metrics awaiting inclusion in a new release.
- `not_used`: Metric is not used in any dashboard.
- `deprecated`: Metric is deprecated and possibly planned to be removed.
- `removed`: Metric was removed, but it may appear in Usage Ping payloads sent from instances running on older versions of GitLab.

### Example YAML metric definition

The linked [`uuid`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/license/uuid.yml)
YAML file includes an example metric definition, where the `uuid` metric is the GitLab
instance unique identifier.

```yaml
key_path: uuid
description: GitLab instance unique identifier
product_category: collection
product_section: growth
product_stage: growth
product_group: group::product intelligence
value_type: string
status: data_available
milestone: 9.1
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

## Create a new metric definition

The GitLab codebase provides a dedicated [generator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/generators/gitlab/usage_metric_definition_generator.rb) to create new metric definitions.

For uniqueness, the generated file includes a timestamp prefix, in ISO 8601 format.

The generator takes the key path argument and 2 options and creates the metric YAML definition in corresponding location:

- `--ee`, `--no-ee` Indicates if metric is for EE.
- `--dir=DIR` indicates the metric directory. It must be one of: `counts_7d`, `7d`, `counts_28d`, `28d`, `counts_all`, `all`, `settings`, `license`.

```shell
bundle exec rails generate gitlab:usage_metric_definition counts.issues --dir=7d
create  config/metrics/counts_7d/issues.yml
```

NOTE:
To create a metric definition used in EE, add the `--ee` flag.

```shell
bundle exec rails generate gitlab:usage_metric_definition counts.issues --ee --dir=7d
create  ee/config/metrics/counts_7d/issues.yml
```

## Metrics added dynamic to Usage Ping payload

The [Redis HLL metrics](index.md#known-events-are-added-automatically-in-usage-data-payload) are added automatically to Usage Ping payload.

A YAML metric definition is required for each metric. A dedicated generator is provided to create metric definitions for Redis HLL events.

The generator takes `category` and `event` arguments, as the root key will be `redis_hll_counters`, and creates two metric definitions for weekly and monthly timeframes:

```shell
bundle exec rails generate gitlab:usage_metric_definition:redis_hll issues i_closed
create  config/metrics/counts_7d/i_closed_weekly.yml
create  config/metrics/counts_28d/i_closed_monthly.yml
```
