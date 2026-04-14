---
stage: Activation
group: Activation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Quick start for activation engine tracking
---

The activation engine uses
[internal events](../internal_analytics/internal_event_instrumentation/_index.md)
to record activation metrics. Events are routed to the activation engine
through YAML-based `extra_trackers` configuration. You do not call the
`Activation::Metric` model directly from application code.

## Record a metric

Call `Gitlab::InternalEvents.track_event` with an internal event whose
YAML definition includes an `extra_trackers` entry for
`Gitlab::Tracking::ActivationTracking`.

```ruby
Gitlab::InternalEvents.track_event('merged_mr', user: user, project: project)
```

The corresponding event definition at `ee/config/events/merged_mr.yml`
wires the event to activation tracking:

```yaml
action: merged_mr
internal_events: true
extra_trackers:
  - tracking_class: Gitlab::Tracking::ActivationTracking
```

The `Gitlab::Tracking::ActivationTracking` adapter receives the event and delegates to
`Activation::Metric.track`. The call is a no-op when:

- The `activation_tracking` feature flag is disabled.
- A record already exists for the same user, namespace, and metric combination.

## Check if a metric is completed

```ruby
Activation::Metric.completed?(user_id: user.id, metric: :merged_mr, namespace_id: namespace.id)
```

Returns `true` if a matching record exists, `false` otherwise.
The `namespace_id:` parameter is optional.

## Query metrics

Use `Activation::MetricsFinder` to retrieve metrics for a user with
optional filters.

```ruby
Activation::MetricsFinder.new(user: user, params: { namespace: namespace, metric: :merged_mr }).execute
```

Supported filter parameters:

- `namespace`: Filter by a specific namespace.
- `metric`: Filter by metric type (symbol).

The finder does not apply a default limit. When used in a GraphQL resolver,
pagination is handled by `.connection_type`.

## Add a new metric type

1. Add an entry to the enum in `ee/app/models/activation/metric.rb`:

   ```ruby
   enum :metric, {
     merged_mr: 0,
     new_metric: 1
   }
   ```

1. Create or update an event definition YAML in `ee/config/events/` with
   the `extra_trackers` entry for `Gitlab::Tracking::ActivationTracking`. The event `action`
   must match the enum key:

   ```yaml
   action: new_metric
   internal_events: true
   extra_trackers:
     - tracking_class: Gitlab::Tracking::ActivationTracking
   ```

1. Ensure application code calls `Gitlab::InternalEvents.track_event`
   for the corresponding event at the appropriate location.

## Feature flag

The `activation_tracking` flag is a `:wip` type flag. To enable it in
development:

```ruby
Feature.enable(:activation_tracking)
```

To enable for a specific user:

```ruby
Feature.enable(:activation_tracking, user)
```

## Test activation metrics

Use the `:activation_metric` factory and `stub_feature_flags` to test
activation tracking.

```ruby
RSpec.describe 'example', feature_category: :onboarding do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }

  describe '.track' do
    before do
      stub_feature_flags(activation_tracking: user)
    end

    it 'records the metric', :aggregate_failures do
      Activation::Metric.track(:merged_mr, user: user, namespace: namespace)

      record = Activation::Metric.last
      expect(record.user_id).to eq(user.id)
      expect(record.namespace_id).to eq(namespace.id)
      expect(record.metric).to eq('merged_mr')
    end
  end

  describe '.completed?' do
    before_all do
      create(:activation_metric, user: user, namespace: namespace)
    end

    it 'returns true when the metric exists' do
      expect(Activation::Metric.completed?(user_id: user.id, metric: :merged_mr, namespace_id: namespace.id))
        .to be(true)
    end
  end
end
```
