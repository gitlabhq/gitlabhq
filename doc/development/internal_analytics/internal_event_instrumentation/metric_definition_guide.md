---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Metrics definitions
---

Metrics are defined in YAML files located in subfolders of `config/metrics` and `ee/config/metrics`.
The YAML files are called metrics definitions.

This page describes the subsection of metric definitions with `data_source: internal_events`.
You can find a general overview of metric definition files in the [Metric Dictionary Guide](../metrics/metrics_dictionary.md)

## Supported metric types

Internal events supports three different metric types which are grouped like this:

1. All time total counters
1. Time framed total counters
1. Time framed unique counters

| Count type / Time frame | `7d` / `28d`                | `all`                   |
|-------------------------|-----------------------------|-------------------------|
| **Total count**         | Time framed total counters  | All time total counters |
| **Unique count**        | Time framed unique counters |                         |

You can tell if a metric is counting unique values or total values by looking at the [event selection rules](#event-selection-rules).

A snippet from a unique metric could look like below. Notice the `unique` property which defines which [identifier](event_definition_guide.md#event-definition-and-validation) of the `create_merge_request` event is used for counting the unique values.

```yaml
events:
  - name: create_merge_request
    unique: user.id
```

Similarly, a snippet from a total count metric can look like below. Notice how there is no `unique` property.

```yaml
events:
  - name: create_merge_request
```

We can track multiple events within one metric via [aggregated metrics](#aggregated-metrics).

### All time total counters

Example: Total visits to /groups/:group/-/analytics/productivity_analytics all time

```yaml
data_category: optional
key_path: counts.productivity_analytics_views
description: Total visits to /groups/:group/-/analytics/productivity_analytics all time
product_group: optimize
value_type: number
status: active
time_frame: all
data_source: internal_events
events:
- name: view_productivity_analytics
tiers:
- premium
- ultimate
performance_indicator_type: []
milestone: "<13.9"
```

The combination of `time_frame: all` and the event selection rule under `events` referring to the
`view_productivity_analytics` event means that this is an "all time total count" metric.

### Time framed total counters

An example is: Weekly count of Runner usage CSV report exports

```yaml
key_path: counts.count_total_export_runner_usage_by_project_as_csv_weekly
description: Weekly count of Runner usage CSV report exports
product_group: runner
performance_indicator_type: []
value_type: number
status: active
milestone: '16.9'
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142328
data_source: internal_events
data_category: optional
tiers:
  - ultimate
time_frame: 7d
events:
  - name: export_runner_usage_by_project_as_csv
```

The combination of `time_frame: 7d` and the event selection rule under `events` referring to the
`export_runner_usage_by_project_as_csv` event means that this is a "timed framed total count" metric.

### Time framed unique counters

Example: Count of distinct users who opted to filter out anonymous users on the analytics dashboard view in the last 28 days.

```yaml
key_path: count_distinct_user_id_from_exclude_anonymised_users_28d
description: Count of distinct users who opted to filter out anonymous users on the analytics dashboard view in the last 28 days.
product_group: platform_insights
performance_indicator_type: []
value_type: number
status: active
milestone: '16.7'
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138150
time_frame: 28d
data_source: internal_events
data_category: optional
tiers:
- ultimate
events:
- name: exclude_anonymised_users
  unique: user.id
```

The combination of `time_frame: 28d`, the event selection rule under `events` referring to the
`exclude_anonymised_users` event and the unique value (`unique: user.id`) means that this is a "timed framed unique count" metric.

## Event Selection Rules

Event selection rules are the parts which connects metric definitions and event definitions.
They are needed to know which metrics should be updated when an event is triggered.

Each internal event based metric should have a least one event selection rule with the following properties.

| Property           | Required | Additional information                                                                                                                                        |
|--------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`             | yes      | Name of the event                                                                                                                                             |
| `unique`           | no       | Used if the metric should count the distinct number of users, projects, namespaces, or count the unique values for additional properties present in the event. Valid values are `user.id`, `project.id` and `namespace.id`. Additionally `label`, `property`, and `value` may also be used in reference to any [additional properties](quick_start.md#additional-properties) included with the event. |
| `filter`           | no       | Used when only a subset of events should be included in the metric. Only additional properties can be used for filtering.                                     |

An example of a single event selection rule which updates a unique count metric when an event called `pull_package` with additional property `label` with the value `rubygems` occurs:

```yaml
- name: pull_package
  unique: user.id
  filter:
    label: rubygems
```

### Filters

Filters are used to constrain which events cause an metric to increase.

This filter includes only `pull_package` events with `label: rubygems`:

```yaml
- name: pull_package
  filter:
    label: rubygems
```

Whereas, this filter is even more restricted and only includes `pull_package` events with `label: rubygems` and `property: deploy_token`:

```yaml
- name: pull_package
  filter:
    label: rubygems
    property: deploy_token
```

Filters support also [custom additional properties](quick_start.md#additional-properties):

```yaml
- name: pull_package
  filter:
    custom_key: custom_value
```

Filters only support matching of exact values and not wildcards or regular expressions.

## Aggregated metrics

A metric definition with several event selection rules can be considered an aggregated metric.

If you want to get total number of `pull_package` and `push_package` events you have to add two event selection rules:

```yaml
events:
- name: pull_package
- name: push_package
```

To get the number of unique users that have at least pushed or pulled a package once:

```yaml
events:
- name: pull_package
  unique: user.id
- name: push_package
  unique: user.id
```

Notice that unique metrics and total count metrics cannot be mixed in a single metric.
