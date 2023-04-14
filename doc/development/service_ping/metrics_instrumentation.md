---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Metrics instrumentation guide

This guide describes how to develop Service Ping metrics using metrics instrumentation.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video tutorial, see the [Adding Service Ping metric via instrumentation class](https://youtu.be/p2ivXhNxUoY).

## Nomenclature

- **Instrumentation class**:
  - Inherits one of the metric classes: `DatabaseMetric`, `RedisMetric`, `RedisHLLMetric`, `NumbersMetric` or `GenericMetric`.
  - Implements the logic that calculates the value for a Service Ping metric.

- **Metric definition**
  The Service Data metric YAML definition.

- **Hardening**:
  Hardening a method is the process that ensures the method fails safe, returning a fallback value like -1.

## How it works

A metric definition has the [`instrumentation_class`](metrics_dictionary.md) field, which can be set to a class.

The defined instrumentation class should inherit one of the existing metric classes: `DatabaseMetric`, `RedisMetric`, `RedisHLLMetric`, `NumbersMetric` or `GenericMetric`.

The current convention is that a single instrumentation class corresponds to a single metric. On rare occasions, there are exceptions to that convention like [Redis metrics](#redis-metrics). To use a single instrumentation class for more than one metric, please reach out to one of the `@gitlab-org/analytics-section/product-intelligence/engineers` members to consult about your case.

Using the instrumentation classes ensures that metrics can fail safe individually, without breaking the entire
 process of Service Ping generation.

We have built a domain-specific language (DSL) to define the metrics instrumentation.

## Database metrics

You can use database metrics to track data kept in the database, for example, a count of issues that exist on a given instance.

- `operation`: Operations for the given `relation`, one of `count`, `distinct_count`, `sum`, and `average`.
- `relation`: Assigns lambda that returns the `ActiveRecord::Relation` for the objects we want to perform the `operation`. The assigned lambda can accept up to one parameter. The parameter is hashed and stored under the `options` key in the metric definition.
- `start`: Specifies the start value of the batch counting, by default is `relation.minimum(:id)`.
- `finish`: Specifies the end value of the batch counting, by default is `relation.maximum(:id)`.
- `cache_start_and_finish_as`: Specifies the cache key for `start` and `finish` values and sets up caching them. Use this call when `start` and `finish` are expensive queries that should be reused between different metric calculations.
- `available?`: Specifies whether the metric should be reported. The default is `true`.
- `timestamp_column`: Optionally specifies timestamp column for metric used to filter records for time constrained metrics. The default is `created_at`.

[Example of a merge request that adds a database metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60022).

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

### Ordinary batch counters Example

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

### Distinct batch counters Example

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

### Sum Example

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

### Average Example

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

## Redis metrics

You can use Redis metrics to track events not kept in the database, for example, a count of how many times the search bar has been used.

[Example of a merge request that adds `Redis` metrics](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103455).

The `RedisMetric` class can only be used as the `instrumentation_class` for Redis metrics with simple counters classes (classes that only inherit `BaseCounter` and set `PREFIX` and `KNOWN_EVENTS` constants). In case the counter class has additional logic included in it, a new `instrumentation_class`, inheriting from `RedisMetric`, needs to be created. This new class needs to include the additional logic from the counter class.

Required options:

- `event`: the event name.
- `prefix`: the value of the `PREFIX` constant used in the counter classes from the `Gitlab::UsageDataCounters` namespace.

Count unique values for `source_code_pushes` event.

```yaml
time_frame: all
data_source: redis
instrumentation_class: RedisMetric
options:
  event: pushes
  prefix: source_code
```

### Availability-restrained Redis metrics

If the Redis metric should only be available in the report under some conditions, then you must specify these conditions in a new class that is a child of the `RedisMetric` class.

```ruby
# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class MergeUsageCountRedisMetric < RedisMetric
          available? { Feature.enabled?(:merge_usage_data_missing_key_paths) }
        end
      end
    end
  end
end
```

You must also use the class's name in the YAML setup.

```yaml
time_frame: all
data_source: redis
instrumentation_class: MergeUsageCountRedisMetric
options:
  event: pushes
  prefix: source_code
```

## Redis HyperLogLog metrics

You can use Redis HyperLogLog metrics to track events not kept in the database and incremented for unique values such as unique users,
for example, a count of how many different users used the search bar.

[Example of a merge request that adds a `RedisHLL` metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61685).

Count unique values for `i_quickactions_approve` event.

```yaml
time_frame: 28d
data_source: redis_hll
instrumentation_class: RedisHLLMetric
options:
  events:
    - i_quickactions_approve
```

### Availability-restrained Redis HyperLogLog metrics

If the Redis HyperLogLog metric should only be available in the report under some conditions, then you must specify these conditions in a new class that is a child of the `RedisHLLMetric` class.

```ruby
# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class MergeUsageCountRedisHLLMetric < RedisHLLMetric
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
data_source: redis_hll
instrumentation_class: MergeUsageCountRedisHLLMetric
options:
  events:
    - i_quickactions_approve
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
  [Database sourced aggregated metrics](implement.md#database-sourced-aggregated-metrics) and
  [Redis sourced aggregated metrics](implement.md#redis-sourced-aggregated-metrics).
- `options.aggregate.operator`: Operator that defines how the aggregated metric data is counted. Available operators are:
  - `OR`: Removes duplicates and counts all entries that triggered any of the listed events.
  - `AND`: Removes duplicates and counts all elements that were observed triggering all of the following events.
- `options.aggregate.attribute`: Information pointing to the attribute that is being aggregated across events.
- `time_frame`: One or more valid time frames. Use these to limit the data included in aggregated metrics to events within a specific date-range. Valid time frames are:
  - `7d`: The last 7 days of data.
  - `28d`: The last 28 days of data.
  - `all`: All historical data, only available for `database` sourced aggregated metrics.
- `data_source`: Data source used to collect all events data included in the aggregated metrics. Valid data sources are:
  - [`database`](implement.md#database-sourced-aggregated-metrics)
  - [`redis_hll`](implement.md#redis-sourced-aggregated-metrics)

Refer to merge request [98206](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98206) for an example of a merge request that adds an `AggregatedMetric` metric.

Count unique `user_ids` that occurred in at least one of the events: `incident_management_alert_status_changed`,
`incident_management_alert_assigned`, `incident_management_alert_todo`, `incident_management_alert_create_incident`.

```yaml
time_frame: 28d
instrumentation_class: AggregatedMetric
data_source: redis_hll
options:
    aggregate:
        operator: OR
        attribute: user_id
    events:
        - `incident_management_alert_status_changed`
        - `incident_management_alert_assigned`
        - `incident_management_alert_todo`
        - `incident_management_alert_create_incident`
```

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
        operator: OR
        attribute: user_id
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

You can use generic metrics for other metrics, for example, an instance's database version. Observations type of data will always have a Generic metric counter type.

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

## Support for instrumentation classes

There is support for:

- `count`, `distinct_count`, `estimate_batch_distinct_count`, `sum`, and `average` for [database metrics](#database-metrics).
- [Redis metrics](#redis-metrics).
- [Redis HLL metrics](#redis-hyperloglog-metrics).
- `add` for [numbers metrics](#numbers-metrics).
- [Generic metrics](#generic-metrics), which are metrics based on settings or configurations.

There is no support for:

- `add`, `histogram` for database metrics.

You can [track the progress to support these](https://gitlab.com/groups/gitlab-org/-/epics/6118).

## Create a new metric instrumentation class

To create a stub instrumentation for a Service Ping metric, you can use a dedicated [generator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/generators/gitlab/usage_metric_generator.rb):

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
- [Redis HyperLogLog metrics](#redis-hyperloglog-metrics)
- [Redis metric](#redis-metrics)
- [Numbers metric](#numbers-metrics)
- [Generic metric](#generic-metrics)

1. Determine the location of instrumentation class: either under `ee` or outside `ee`.

1. [Generate the instrumentation class file](#create-a-new-metric-instrumentation-class).

1. Fill the instrumentation class body:

   - Add code logic for the metric. This might be similar to the metric implementation in `usage_data.rb`.
   - Add tests for the individual metric [`spec/lib/gitlab/usage/metrics/instrumentations/`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/usage/metrics/instrumentations).
   - Add tests for Service Ping.

1. [Generate the metric definition file](metrics_dictionary.md#create-a-new-metric-definition).

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
