---
stage: Fulfillment
group: License
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Licensed feature availability

As of GitLab 9.4, we've been supporting a simplified version of licensed
feature availability checks via `ee/app/models/license.rb`, both for
on-premise or GitLab.com plans and features.

## Restricting features scoped by namespaces or projects

GitLab.com plans are persisted on user groups and namespaces, therefore, if you're adding a
feature such as [Related issues](../user/project/issues/related_issues.md) or
[Service Desk](../user/project/service_desk.md),
it should be restricted on namespace scope.

1. Add the feature symbol on `EES_FEATURES`, `EEP_FEATURES`, or `EEU_FEATURES` constants in
  `ee/app/models/license.rb`. Note that the prefix `EES` signifies Starter, `EEP` signifies
  Premium, and `EEU` signifies Ultimate.
1. Check using:

```ruby
project.feature_available?(:feature_symbol)
```

## Restricting global features (instance)

However, for features such as [Geo](../administration/geo/index.md) and
[Load balancing](../administration/database_load_balancing.md), which cannot be restricted
to only a subset of projects or namespaces, the check is made directly in
the instance license.

1. Add the feature symbol on `EES_FEATURES`, `EEP_FEATURES` or `EEU_FEATURES` constants in
  `ee/app/models/license.rb`.
1. Add the same feature symbol to `GLOBAL_FEATURES`.
1. Check using:

```ruby
License.feature_available?(:feature_symbol)
```

## Restricting frontend features

To restrict frontend features based on the license, use `push_licensed_feature`.
The frontend can then access this via `this.glFeatures`:

```ruby
before_action do
  push_licensed_feature(:feature_symbol)
  # or by project/namespace
  push_licensed_feature(:feature_symbol, project)
end
```
