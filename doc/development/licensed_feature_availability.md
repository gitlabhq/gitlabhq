# Licensed feature availability **(STARTER)**

As of GitLab 9.4, we've been supporting a simplified version of licensed
feature availability checks via `ee/app/models/license.rb`, both for
on-premise or GitLab.com plans and features.

## Restricting features scoped by namespaces or projects

GitLab.com plans are persisted on user groups and namespaces, therefore, if you're adding a
feature such as [Related issues](../user/project/issues/related_issues.md) or
[Service desk](../user/project/service_desk.md),
it should be restricted on namespace scope.

1. Add the feature symbol on `EES_FEATURES`, `EEP_FEATURES` or `EEU_FEATURES` constants in
  `ee/app/models/license.rb`. Note on `ee/app/models/ee/namespace.rb` that _Bronze_ GitLab.com
  features maps to on-premise _EES_, _Silver_ to _EEP_ and _Gold_ to _EEU_.
1. Check using:

```ruby
project.feature_available?(:feature_symbol)
```

## Restricting global features (instance)

However, for features such as [Geo](../administration/geo/replication/index.md) and
[Load balancing](../administration/database_load_balancing.md), which cannot be restricted
to only a subset of projects or namespaces, the check will be made directly in
the instance license.

1. Add the feature symbol on `EES_FEATURES`, `EEP_FEATURES` or `EEU_FEATURES` constants in
  `ee/app/models/license.rb`.
1. Add the same feature symbol to `GLOBAL_FEATURES`
1. Check using:

```ruby
License.feature_available?(:feature_symbol)
```

## Enabling promo features on GitLab.com

A paid feature can be made available to everyone on GitLab.com by enabling the feature flag `"promo_#{feature}"`.
