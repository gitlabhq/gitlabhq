---
stage: Activation
group: Activation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Quick start for activation engine tracking
---

To instrument your code with the activation engine, use the
`Activation::Metric` model directly. No event definitions or YAML
configuration files are required.

## Record a metric

Call `Activation::Metric.track` from any service, worker, or controller.
The method is gated behind the `activation_tracking` feature flag and
is a no-op when the flag is disabled.

```ruby
Activation::Metric.track(:merged_mr, user: user, namespace: project.namespace)
```

- `metric` (required): A symbol matching an entry in the `Activation::Metric` enum.
- `user:` (required): The user who completed the action.
- `namespace:` (optional): The namespace context. Subgroups are automatically
  resolved to the root namespace.

The method uses `safe_find_or_create_by!` internally. If a record already
exists for the same user, namespace, and metric combination, the existing
record is returned without creating a duplicate.

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

1. Optional. Create a feature flag to toggle tracking for the new metric
   independently of the global `activation_tracking` flag. Check the flag
   at the call site before calling `Activation::Metric.track`.

1. Call `Activation::Metric.track(:new_metric, user: user)` from the
   appropriate location in the codebase.

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
