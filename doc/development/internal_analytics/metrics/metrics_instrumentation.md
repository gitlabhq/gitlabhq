---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Metrics instrumentation guide

This guide describes how to develop Service Ping metrics using metrics instrumentation.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video tutorial, see the [Adding Service Ping metric via instrumentation class](https://youtu.be/p2ivXhNxUoY).

## Nomenclature

- **Instrumentation class**:
  - Inherits one of the metric classes: `DatabaseMetric`, `NumbersMetric` or `GenericMetric`.
  - Implements the logic that calculates the value for a Service Ping metric.

- **Metric definition**
  The Service Data metric YAML definition.

- **Hardening**:
  Hardening a method is the process that ensures the method fails safe, returning a fallback value like -1.

## How it works

A metric definition has the [`instrumentation_class`](metrics_dictionary.md) field, which can be set to a class.

The defined instrumentation class should inherit one of the existing metric classes: `DatabaseMetric`, `NumbersMetric` or `GenericMetric`.

The current convention is that a single instrumentation class corresponds to a single metric.

Using an instrumentation class ensures that metrics can fail safe individually, without breaking the entire process of Service Ping generation.

## Database metrics

NOTE:
Whenever possible we recommend using [internal event tracking](../internal_event_instrumentation/quick_start.md) instead of database metrics.
Database metrics can create unnecessary load on the database of bigger GitLab instances and potential optimisations can affect instance performance.

You can use database metrics to track data kept in the database, for example, a count of issues that exist on a given instance.

- `operation`: Operations for the given `relation`, one of `count`, `distinct_count`, `sum`, and `average`.
- `relation`: Assigns lambda that returns the `ActiveRecord::Relation` for the objects we want to perform the `operation`. The assigned lambda can accept up to one parameter. The parameter is hashed and stored under the `options` key in the metric definition.
- `start`: Specifies the start value of the batch counting, by default is `relation.minimum(:id)`.
- `finish`: Specifies the end value of the batch counting, by default is `relation.maximum(:id)`.
- `cache_start_and_finish_as`: Specifies the cache key for `start` and `finish` values and sets up caching them. Use this call when `start` and `finish` are expensive queries that should be reused between different metric calculations.
- `available?`: Specifies whether the metric should be reported. The default is `true`.
- `timestamp_column`: Optionally specifies timestamp column for metric used to filter records for time constrained metrics. The default is `created_at`.

[Example of a merge request that adds a database metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60022).

### Optimization recommendations and examples

Any single query for a Service Ping metric must stay below the [1 second execution time](../../database/query_performance.md#timing-guidelines-for-queries) with cold caches.

- Use specialized indexes. For examples, see these merge requests:
  - [Example 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26871)
  - [Example 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26445)
- Use defined `start` and `finish`. These values can be memoized and reused, as in this
  [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37155).
- Avoid joins and unnecessary complexity in your queries. See this
  [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36316) as an example.
- Set a custom `batch_size` for `distinct_count`, as in this [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38000).

### Database metric Examples

#### Count Example

```ruby
module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountIssuesMetric < DatabaseMetric
          operation :count

          relation ->(options) { Issue.where(confidential: options[:confidential]) }
        end
      end
    end
  end
end
```

#### Batch counters Example

```ruby
module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountIssuesMetric < DatabaseMetric
          operation :count

          start { Issue.minimum(:id) }
          finish { Issue.maximum(:id) }

          relation { Issue }
        end
      end
    end
  end
end
```

#### Distinct batch counters Example

```ruby
# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersAssociatingMilestonesToReleasesMetric < DatabaseMetric
          operation :distinct_count, column: :author_id

          relation { Release.with_milestones }

          start { Release.minimum(:author_id) }
          finish { Release.maximum(:author_id) }
        end
      end
    end
  end
end
```

#### Sum Example

```ruby
# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class JiraImportsTotalImportedIssuesCountMetric < DatabaseMetric
          operation :sum, column: :imported_issues_count

          relation { JiraImportState.finished }
        end
      end
    end
  end
end
```

#### Average Example

```ruby
# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountIssuesWeightAverageMetric < DatabaseMetric
          operation :average, column: :weight

          relation { Issue }
        end
      end
    end
  end
end
```

#### Estimated batch counters

Estimated batch counter functionality handles `ActiveRecord::StatementInvalid` errors
when used through the provided `estimate_batch_distinct_count` method.
Errors return a value of `-1`.

WARNING:
This functionality estimates a distinct count of a specific ActiveRecord_Relation in a given column,
which uses the [HyperLogLog](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/40671.pdf) algorithm.
As the HyperLogLog algorithm is probabilistic, the **results always include error**.
The highest encountered error rate is 4.9%.

When correctly used, the `estimate_batch_distinct_count` method enables efficient counting over
columns that contain non-unique values, which cannot be assured by other counters.

##### `estimate_batch_distinct_count` method

Method:

```ruby
estimate_batch_distinct_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
```

The [method](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/utils/usage_data.rb#L63)
includes the following arguments:

- `relation`: The ActiveRecord_Relation to perform the count.
- `column`: The column to perform the distinct count. The default is the primary key.
- `batch_size`: From `Gitlab::Database::PostgresHll::BatchDistinctCounter::DEFAULT_BATCH_SIZE`. Default value: 10,000.
- `start`: The custom start of the batch count, to avoid complex minimum calculations.
- `finish`: The custom end of the batch count to avoid complex maximum calculations.

The method includes the following prerequisites:

- The supplied `relation` must include the primary key defined as the numeric column.
  For example: `id bigint NOT NULL`.
- The `estimate_batch_distinct_count` can handle a joined relation. To use its ability to
  count non-unique columns, the joined relation **must not** have a one-to-many relationship,
  such as `has_many :boards`.
- Both `start` and `finish` arguments should always represent primary key relationship values,
  even if the estimated count refers to another column, for example:

  ```ruby
    estimate_batch_distinct_count(::Note, :author_id, start: ::Note.minimum(:id), finish: ::Note.maximum(:id))
  ```

Examples:

1. Simple execution of estimated batch counter, with only relation provided,
   returned value represents estimated number of unique values in `id` column
   (which is the primary key) of `Project` relation:

   ```ruby
     estimate_batch_distinct_count(::Project)
   ```

1. Execution of estimated batch counter, where provided relation has applied
   additional filter (`.where(time_period)`), number of unique values estimated
   in custom column (`:author_id`), and parameters: `start` and `finish` together
   apply boundaries that defines range of provided relation to analyze:

   ```ruby
     estimate_batch_distinct_count(::Note.with_suggestions.where(time_period), :author_id, start: ::Note.minimum(:id), finish: ::Note.maximum(:id))
   ```

## Aggregated metrics

<div class="video-fallback">
  See the video from: <a href="https://www.youtube.com/watch?v=22LbYqHwtUQ">Product Intelligence Office Hours Oct 6th</a> for an aggregated metrics walk-through.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/22LbYqHwtUQ" frameborder="0" allowfullscreen> </iframe>
</figure>

The aggregated metrics feature provides insight into the number of data attributes, for example `pseudonymized_user_ids`, that occurred in a collection of events. For example, you can aggregate the number of users who perform multiple actions such as creating a new issue and opening
a new merge request.

You can use a YAML file to define your aggregated metrics. The following arguments are required:

- `options.events`: List of event names to aggregate into metric data. All events in this list must
  use the same data source. Additional data source requirements are described in
  [Database sourced aggregated metrics](#database-sourced-aggregated-metrics) and
  [Event sourced aggregated metrics](#event-sourced-aggregated-metrics).
- `options.aggregate.attribute`: Information pointing to the attribute that is being aggregated across events.
- `time_frame`: One or more valid time frames. Use these to limit the data included in aggregated metrics to events within a specific date-range. Valid time frames are:
  - `7d`: The last 7 days of data.
  - `28d`: The last 28 days of data.
  - `all`: All historical data, only available for `database` sourced aggregated metrics.
- `data_source`: Data source used to collect all events data included in the aggregated metrics. Valid data sources are:
  - [`database`](#database-sourced-aggregated-metrics)
  - [`internal_events`](#event-sourced-aggregated-metrics)
  - `redis_hll`: deprecated metrics using RedisHLL directly

Refer to merge request [98206](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98206) for an example of a merge request that adds an `AggregatedMetric` metric.

Count unique `user.id`s that occurred in at least one of the events: `incident_management_alert_status_changed`,
`incident_management_alert_assigned`, `incident_management_alert_todo`, `incident_management_alert_create_incident`.

```yaml
time_frame: 28d
instrumentation_class: AggregatedMetric
data_source: internal_events
options:
    aggregate:
        attribute: user.id
    events:
        - `incident_management_alert_status_changed`
        - `incident_management_alert_assigned`
        - `incident_management_alert_todo`
        - `incident_management_alert_create_incident`
```

### Event sourced aggregated metrics

To declare the aggregate of events collected with Internal Events, make sure `time_frame` does not include the `all` value, which is unavailable for Redis-sourced aggregated metrics.

While it is possible to aggregate EE-only events together with events that occur in all GitLab editions, it's important to remember that doing so may produce high variance between data collected from EE and CE GitLab instances.

### Database sourced aggregated metrics

To declare an aggregate of metrics based on events collected from database, follow
these steps:

1. [Persist the metrics for aggregation](#persist-metrics-for-aggregation).
1. [Add new aggregated metric definition](#add-new-aggregated-metric-definition).

#### Persist metrics for aggregation

Only metrics calculated with [Estimated Batch Counters](#estimated-batch-counters)
can be persisted for database sourced aggregated metrics. To persist a metric,
inject a Ruby block into the
[`estimate_batch_distinct_count`](#estimate_batch_distinct_count-method) method.
This block should invoke the
`Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll.save_aggregated_metrics`
[method](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage/metrics/aggregates/sources/postgres_hll.rb#L21),
which stores `estimate_batch_distinct_count` results for future use in aggregated metrics.

The `Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll.save_aggregated_metrics`
method accepts the following arguments:

- `metric_name`: The name of metric to use for aggregations. Should be the same
  as the key under which the metric is added into Service Ping.
- `recorded_at_timestamp`: The timestamp representing the moment when a given
  Service Ping payload was collected. You should use the convenience method `recorded_at`
  to fill `recorded_at_timestamp` argument, like this: `recorded_at_timestamp: recorded_at`
- `time_period`: The time period used to build the `relation` argument passed into
  `estimate_batch_distinct_count`. To collect the metric with all available historical
  data, set a `nil` value as time period: `time_period: nil`.
- `data`: HyperLogLog buckets structure representing unique entries in `relation`.
  The `estimate_batch_distinct_count` method always passes the correct argument
  into the block, so `data` argument must always have a value equal to block argument,
  like this: `data: result`

Example metrics persistence:

```ruby
class UsageData
  def count_secure_pipelines(time_period)
    ...
    relation = ::Security::Scan.by_scan_types(scan_type).where(time_period)

    pipelines_with_secure_jobs['dependency_scanning_pipeline'] = estimate_batch_distinct_count(relation, :pipeline_id, batch_size: 1000, start: start_id, finish: finish_id) do |result|
      ::Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
        .save_aggregated_metrics(metric_name: 'dependency_scanning_pipeline', recorded_at_timestamp: recorded_at, time_period: time_period, data: result)
    end
  end
end
```

#### Add new aggregated metric definition

After all metrics are persisted, you can add an aggregated metric definition.
To declare the aggregate of metrics collected with [Estimated Batch Counters](#estimated-batch-counters),
you must fulfill the following requirements:

- Metrics names listed in the `events:` attribute, have to use the same names you passed in the `metric_name` argument while persisting metrics in previous step.
- Every metric listed in the `events:` attribute, has to be persisted for **every** selected `time_frame:` value.

### Availability-restrained Aggregated metrics

If the Aggregated metric should only be available in the report under specific conditions, then you must specify these conditions in a new class that is a child of the `AggregatedMetric` class.

```ruby
# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class MergeUsageCountAggregatedMetric < AggregatedMetric
          available? { Feature.enabled?(:merge_usage_data_missing_key_paths) }
        end
      end
    end
  end
end
```

You must also use the class's name in the YAML setup.

```yaml
time_frame: 28d
instrumentation_class: MergeUsageCountAggregatedMetric
data_source: redis_hll
options:
    aggregate:
        attribute: user.id
    events:
        - `incident_management_alert_status_changed`
        - `incident_management_alert_assigned`
        - `incident_management_alert_todo`
        - `incident_management_alert_create_incident`
```

## Numbers metrics

- `operation`: Operations for the given `data` block. Currently we only support `add` operation.
- `data`: a `block` which contains an array of numbers.
- `available?`: Specifies whether the metric should be reported. The default is `true`.

```ruby
# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
          class IssuesBoardsCountMetric < NumbersMetric
            operation :add

            data do |time_frame|
              [
                 CountIssuesMetric.new(time_frame: time_frame).value,
                 CountBoardsMetric.new(time_frame: time_frame).value
              ]
            end
          end
        end
      end
    end
  end
end
```

You must also include the instrumentation class name in the YAML setup.

```yaml
time_frame: 28d
instrumentation_class: IssuesBoardsCountMetric
```

## Generic metrics

You can use generic metrics for other metrics, for example, an instance's database version.

- `value`: Specifies the value of the metric.
- `available?`: Specifies whether the metric should be reported. The default is `true`.

[Example of a merge request that adds a generic metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60256).

```ruby
module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class UuidMetric < GenericMetric
          value do
            Gitlab::CurrentSettings.uuid
          end
        end
      end
    end
  end
end
```

## Prometheus metrics

This instrumentation class lets you handle Prometheus queries by passing a Prometheus client object as an argument to the `value` block.
Any Prometheus error handling should be done in the block itself.

- `value`: Specifies the value of the metric. A Prometheus client object is passed as the first argument.
- `available?`: Specifies whether the metric should be reported. The default is `true`.

[Example of a merge request that adds a Prometheus metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122400).

```ruby
module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitalyApdexMetric < PrometheusMetric
          value do |client|
            result = client.query('avg_over_time(gitlab_usage_ping:gitaly_apdex:ratio_avg_over_time_5m[1w])').first

            break FALLBACK unless result

            result['value'].last.to_f
          end
        end
      end
    end
  end
end
```

## Create a new metric instrumentation class

<!-- To create a stub instrumentation for a Service Ping metric, you can use a dedicated [generator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/generators/gitlab/usage_metric_generator.rb): -->

The generator takes the class name as an argument and the following options:

- `--type=TYPE` Required. Indicates the metric type. It must be one of: `database`, `generic`, `redis`, `numbers`.
- `--operation` Required for `database` & `numbers` type.
  - For `database` it must be one of: `count`, `distinct_count`, `estimate_batch_distinct_count`, `sum`, `average`.
  - For `numbers` it must be: `add`.
- `--ee` Indicates if the metric is for EE.

```shell
rails generate gitlab:usage_metric CountIssues --type database --operation distinct_count
        create lib/gitlab/usage/metrics/instrumentations/count_issues_metric.rb
        create spec/lib/gitlab/usage/metrics/instrumentations/count_issues_metric_spec.rb
```

## Migrate Service Ping metrics to instrumentation classes

This guide describes how to migrate a Service Ping metric from [`lib/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage_data.rb) or [`ee/lib/ee/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/usage_data.rb) to instrumentation classes.

1. Choose the metric type:

- [Database metric](#database-metrics)
- [Numbers metric](#numbers-metrics)
- [Generic metric](#generic-metrics)

1. Determine the location of instrumentation class: either under `ee` or outside `ee`.

1. [Generate the instrumentation class file](#create-a-new-metric-instrumentation-class).

1. Fill the instrumentation class body:

   - Add code logic for the metric. This might be similar to the metric implementation in `usage_data.rb`.
   - Add tests for the individual metric [`spec/lib/gitlab/usage/metrics/instrumentations/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/usage/metrics/instrumentations).
   - Add tests for Service Ping.

1. [Generate the metric definition file](../metrics/metrics_dictionary.md#create-a-new-metric-definition).

1. Remove the code from [`lib/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage_data.rb) or [`ee/lib/ee/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/usage_data.rb).

1. Remove the tests from [`spec/lib/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/lib/gitlab/usage_data_spec.rb) or [`ee/spec/lib/ee/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/lib/ee/gitlab/usage_data_spec.rb).

## Troubleshoot metrics

Sometimes metrics fail for reasons that are not immediately clear. The failures can be related to performance issues or other problems.
The following pairing session video gives you an example of an investigation in to a real-world failing metric.

<div class="video-fallback">
  See the video from: <a href="https://www.youtube.com/watch?v=y_6m2POx2ug">Product Intelligence Office Hours Oct 27th</a> to learn more about the metrics troubleshooting process.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/y_6m2POx2ug" frameborder="0" allowfullscreen> </iframe>
</figure>
