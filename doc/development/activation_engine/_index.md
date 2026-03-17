---
stage: Activation
group: Activation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Activation engine
---

The activation engine tracks user activation milestones (Setup, Aha, Habit)
for personalization experiments on GitLab.com. It is an independent system,
separate from [internal event tracking](../internal_analytics/internal_event_instrumentation/_index.md).

The activation engine is EE-only and gated behind the `activation_tracking`
feature flag (`:wip` type).

## Architecture

The activation engine stores one record per user, per metric, per namespace
in the `activation_metrics` table. A database-level unique constraint
(with `NULLS NOT DISTINCT`) prevents duplicate records.

| Component | Path | Purpose |
| --- | --- | --- |
| Model | `ee/app/models/activation/metric.rb` | Record, query, and check activation metrics. |
| Finder | `ee/app/finders/activation/metrics_finder.rb` | Filter metrics by user, namespace, and metric type. |
| Feature flag | `ee/config/feature_flags/wip/activation_tracking.yml` | Controls whether tracking is active. |
| Factory | `ee/spec/factories/activation/metrics.rb` | Test factory for `activation_metric`. |

## Available metric types

Metric types are defined in the `Activation::Metric` enum. To add a new metric
type, add an entry to the enum in `ee/app/models/activation/metric.rb`.

```ruby
enum :metric, {
  merged_mr: 0
}
```

## Guides

- [Quick start for activation engine tracking](quick_start.md)
