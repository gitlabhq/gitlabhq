---
source_checksum: a8b2d55fd93bf700
distilled_at_sha: f61a71870e300699d0cbf5f4ba05fb6666928907
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Analytics Instrumentation Principles

## Checklist

### Event Definitions

- Ensure every fired event has a corresponding definition file in `config/events` or `ee/config/events`.
- Verify the [event definition file](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/event_definition_guide/) is correct and complete.
- DO NOT include sensitive information (per the [data classification standard](https://handbook.gitlab.com/handbook/security/data-classification-standard/)) in tracking parameters.
- DO NOT use deprecated analytics methods (`Gitlab::Tracking.event`, Redis, or RedisHLL tracking); use `track_internal_event` (backend) or `trackEvent` (frontend) instead.
- Ensure the `action` name follows the [naming convention](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/quick_start/#defining-event-and-metrics).
- Ensure the event `description` is clear to readers outside the team.
- Place the event definition file under `ee/config/events` if the event fires only from EE code.
- When the `action` field of an existing event changes, confirm the author considered the [renaming implications](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/event_definition_guide/#changing-the-action-property-in-event-definitions).
- When removing an event, verify the [event removal process](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/event_lifecycle/#remove-an-event) was followed.

### Metric Definitions

- Add the `~database` label and request a database review for metrics based on database queries.
- Verify the metric's `description` field is accurate and meaningful.
- Verify the metric's `key_path` is correct.
- Check the `product_group` field corresponds to the [stages file](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml)
- Verify the file location reflects the correct time frame and whether it belongs under `ee/`.
- Verify the metric's tiers are correctly set.
- Prefer `data_source: internal_events` for new metrics; hand off to the Analytics Instrumentation team if `data_source: database` is used.
- DO NOT use deprecated `redis` or `redis_hll` data sources for new metrics; see the [migration guide](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/migration/).
- Ensure changed or removed metrics have notified `@csops-team`, `@gitlab-data/analytics-engineers`, and `@gitlab-data/product-analysts` via a comment on the issue, and all groups have acknowledged the change.
- When updating an existing metric, verify the [metric change procedure](https://docs.gitlab.com/development/internal_analytics/metrics/metrics_lifecycle/#change-an-existing-metric) was followed.

### Metric Instrumentation Classes

- Use `rails generate gitlab:usage_metric ClassName --type TYPE --operation OPERATION` to generate new instrumentation class and spec files; DO NOT create them manually.
- Inherit from `DatabaseMetric`, `NumbersMetric`, or `GenericMetric` (or `PrometheusMetric`) — one instrumentation class per metric.
- Prefer [internal event tracking](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/quick_start/) over `DatabaseMetric`; database metrics can create unnecessary load on larger instances.
- Ensure every Service Ping metric query stays below 1 second execution time with cold caches; use specialized indexes, defined `start`/`finish` values, and avoid joins where possible.
- Use `cache_start_and_finish_as` when `start` and `finish` are expensive queries reused across multiple metrics.
- When using `estimate_batch_distinct_count`, ensure the relation includes a numeric primary key, the joined relation has no one-to-many relationship, and `start`/`finish` always represent primary key values.
- After implementing a new instrumentation class, run Service Ping locally to verify the metric is included and functioning as expected.

### Event Firing Verification

- Verify new events fire correctly locally using the available [testing tools](https://docs.gitlab.com/development/internal_analytics/internal_event_instrumentation/local_setup_and_debugging/).
- Verify new metrics appear in the Service Ping payload by running `require_relative 'spec/support/helpers/service_ping_helpers.rb'; ServicePingHelpers.get_current_usage_metric_value(key_path)` with the metric's `key_path`.

### Backend Tracking

- Call `track_internal_event` from the `Gitlab::InternalEventsTracking` module, passing `user`, `namespace`, and `project` arguments; fill out as many as possible to maximize data quality.
- When a metric uses a `unique` property (e.g., `unique: project.id`), ensure the corresponding argument (e.g., `project`) is always provided to `track_internal_event`.
- Use the `ProductAnalyticsTracking` module for controller-level event tracking and the `Gitlab::InternalEvents::ServiceTracking` concern for service objects instead of calling `track_internal_event` inline.
- When passing `additional_properties`, DO NOT include sensitive information; define each custom property in the event definition's `additional_properties` field.
- When emitting multiple events at once, wrap calls in `Gitlab::InternalEvents.with_batched_redis_writes` to batch Redis writes into a single call.

### Frontend Tracking

- Use the `InternalEvents` Vue mixin (`InternalEvents.mixin()`) for Vue component tracking, raw `InternalEvents.trackEvent(...)` for arbitrary JavaScript, or `data-event-tracking` attributes for declarative HTML/Haml tracking.
- Add `data-event-tracking-load="true"` alongside `data-event-tracking` to fire an event on component render rather than on click.
- DO NOT pass the page URL or page path as an additional property; the pseudonymized page URL is already tracked per event, and `window.location` does not pseudonymize project and namespace information.

### Testing

- Use the `trigger_internal_events` and `increment_usage_metrics` RSpec matchers (not manual stubs) to assert backend event firing and metric increments.
- Use `useMockInternalEventsTracking` / `bindInternalEventDocument` helpers to assert `trackEvent` calls in JavaScript and Vue component tests.
- Use the `trigger_internal_events` matcher with `.on_click` or `.on_load` chain methods to assert Haml data-attribute tracking in view and ViewComponent specs.
- Apply the `:clean_gitlab_redis_shared_state` trait when tests fail due to metrics not being incremented, to clear the Redis cache between examples.

### Internal Events CLI Changes

- Ensure CLI changes follow the [CLI style guide](https://docs.gitlab.com/development/internal_analytics/cli_contribution_guidelines/).
- Verify CLI UX: content is easy to skim, meaningful to people outside the team, and all inputs have clear meaning and effect.
- Verify edge cases and caveats include instructions to validate whether the user needs to act on them.

### Review Labels

- Apply `~analytics instrumentation` and `~analytics instrumentation::review pending` labels when an Analytics Instrumentation review is needed but was not assigned automatically.
- Approve the MR and relabel with `~"analytics instrumentation::approved"` upon completion.
- DO NOT require a maintainer review for `~analytics instrumentation` reviews.

## Authoritative sources

For the full picture, see:

- doc/development/internal_analytics/review_guidelines.md
- doc/development/internal_analytics/internal_event_instrumentation/quick_start.md
- doc/development/internal_analytics/metrics/metrics_instrumentation.md

