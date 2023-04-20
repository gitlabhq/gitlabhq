---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Usage Data Metrics guide

This guide describes deprecated usage for metrics in `usage_data.rb`.

NOTE:
Implementing metrics direct in `usage_data.rb` is deprecated, We recommend you use [instrumentation classes](metrics_instrumentation.md).

## Ordinary batch counters

Simple count of a given `ActiveRecord_Relation`, does a non-distinct batch count, smartly reduces `batch_size`, and handles errors.
Handles the `ActiveRecord::StatementInvalid` error.

Method:

```ruby
count(relation, column = nil, batch: true, start: nil, finish: nil)
```

Arguments:

- `relation` the ActiveRecord_Relation to perform the count
- `column` the column to perform the count on, by default is the primary key
- `batch`: default `true` to use batch counting
- `start`: custom start of the batch counting to avoid complex min calculations
- `end`: custom end of the batch counting to avoid complex min calculations

Examples:

```ruby
count(User.active)
count(::Clusters::Cluster.aws_installed.enabled, :cluster_id)
count(::Clusters::Cluster.aws_installed.enabled, :cluster_id, start: ::Clusters::Cluster.minimum(:id), finish: ::Clusters::Cluster.maximum(:id))
```

## Distinct batch counters

Distinct count of a given `ActiveRecord_Relation` on given column, a distinct batch count, smartly reduces `batch_size`, and handles errors.
Handles the `ActiveRecord::StatementInvalid` error.

Method:

```ruby
distinct_count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
```

Arguments:

- `relation`: the ActiveRecord_Relation to perform the count
- `column`: the column to perform the distinct count, by default is the primary key
- `batch`: default `true` to use batch counting
- `batch_size`: if none set it uses default value 10000 from `Gitlab::Database::BatchCounter`
- `start`: custom start of the batch counting to avoid complex min calculations
- `end`: custom end of the batch counting to avoid complex min calculations

WARNING:
Counting over non-unique columns can lead to performance issues. For more information, see the [iterating tables in batches](../database/iterating_tables_in_batches.md) guide.

Examples:

```ruby
distinct_count(::Project, :creator_id)
distinct_count(::Note.with_suggestions.where(time_period), :author_id, start: ::User.minimum(:id), finish: ::User.maximum(:id))
```
