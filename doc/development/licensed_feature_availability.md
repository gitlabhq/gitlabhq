---
stage: Fulfillment
group: Provision
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

1. Add the feature symbol on `STARTER_FEATURES`, `PREMIUM_FEATURES`, or `ULTIMATE_FEATURES` constants in
  `ee/app/models/gitlab_subscriptions/features.rb`.
1. Check using:

```ruby
project.licensed_feature_available?(:feature_symbol)
```

or

```ruby
group.licensed_feature_available?(:feature_symbol)
```

For projects, `licensed_feature_available` delegates to its associated `namespace`.

## Restricting global features (instance)

However, for features such as [Geo](../administration/geo/index.md) and
[Database Load Balancing](../administration/postgresql/database_load_balancing.md), which cannot be restricted
to only a subset of projects or namespaces, the check is made directly in
the instance license.

1. Add the feature symbol to `STARTER_FEATURES`, `PREMIUM_FEATURES` or `ULTIMATE_FEATURES` constants in
  `ee/app/models/gitlab_subscriptions/features.rb`.
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

## Allow use of licensed EE features

To enable plans per namespace turn on the `Allow use of licensed EE features` option from the settings page.
This will make licensed EE features available to projects only if the project namespace's plan includes the feature
or if the project is public. To enable it:

1. If you are developing locally, follow the steps in [simulate SaaS](ee_features.md#act-as-saas) to make the option available.
1. Select Admin > Settings > General > "Account and limit" and enable "Allow use of licensed EE features".
