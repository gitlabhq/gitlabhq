---
stage: Analytics
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
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

- `operation`: Operations for the given `relation`, one of `count`, `distinct_count`, `sum`, and `average`.
- `relation`: `ActiveRecord::Relation` for the objects we want to perform the `operation`.
- `start`: Specifies the start value of the batch counting, by default is `relation.minimum(:id)`.
- `finish`: Specifies the end value of the batch counting, by default is `relation.maximum(:id)`.
- `cache_start_and_finish_as`: Specifies the cache key for `start` and `finish` values and sets up caching them. Use this call when `start` and `finish` are expensive queries that should be reused between different metric calculations.
- `available?`: Specifies whether the metric should be reported. The default is `true`.

[Example of a merge request that adds a database metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60022).

```ruby
module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountBoardsMetric < DatabaseMetric
          operation :count

          relation { Board }
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

[Example of a merge request that adds a `Redis` metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66582).

Count unique values for `source_code_pushes` event.

Required options:

- `event`: the event name.
- `counter_class`: one of the counter classes from the `Gitlab::UsageDataCounters` namespace; it should implement `read` method or inherit it from `BaseCounter`.

```yaml
time_frame: all
data_source: redis
instrumentation_class: 'RedisMetric'
options:
  event: pushes
  counter_class: SourceCodeCounter
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
instrumentation_class: 'MergeUsageCountRedisMetric'
options:
  event: pushes
  counter_class: SourceCodeCounter
```

## Redis HyperLogLog metrics

[Example of a merge request that adds a `RedisHLL` metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61685).

Count unique values for `i_quickactions_approve` event.

```yaml
time_frame: 28d
data_source: redis_hll
instrumentation_class: 'RedisHLLMetric'
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
instrumentation_class: 'MergeUsageCountRedisHLLMetric'
options:
  events:
    - i_quickactions_approve
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
instrumentation_class: 'IssuesBoardsCountMetric'
```

## Generic metrics

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
- `--operation` Required for `database` & `numebers` type.
  - For `database` it must be one of: `count`, `distinct_count`, `estimate_batch_distinct_count`, `sum`, `average`.
  - For `numbers` it must be: `add`.
- `--ee` Indicates if the metric is for EE.

```shell
rails generate gitlab:usage_metric CountIssues --type database
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
