---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Metrics instrumentation guide

This guide describes how to develop Usage Ping metrics using metrics instrumentation.

## Nomenclature

- **Instrumentation class**:
  - Inherits one of the metric classes: `DatabaseMetric`, `RedisHLLMetric` or `GenericMetric`.
  - Implements the logic that calculates the value for a Usage Ping metric.

- **Metric definition**
  The Usage Data metric YAML definition.

- **Hardening**:
  Hardening a method is the process that ensures the method fails safe, returning a fallback value like -1.

## How it works

A metric definition has the [`instrumentation_class`](metrics_dictionary.md) field, which can be set to a class.

The defined instrumentation class should have one of the existing metric classes: `DatabaseMetric`, `RedisHLLMetric`, or `GenericMetric`.

Using the instrumentation classes ensures that metrics can fail safe individually, without breaking the entire
 process of Usage Ping generation.

We have built a domain-specific language (DSL) to define the metrics instrumentation.

## Database metrics

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

## Redis HyperLogLog metrics

[Example of a merge request that adds a `RedisHLL` metric](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61685).

Count unique values for `i_quickactions_approve` event.

```yaml
time_frame: 28d
data_source: redis_hll
instrumentation_class: 'Gitlab::Usage::Metrics::Instrumentations::RedisHLLMetric'
options:
  events:
    - i_quickactions_approve
```

## Generic metrics

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
