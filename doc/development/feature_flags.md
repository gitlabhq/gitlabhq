# Manage feature flags

Starting from GitLab 9.3 we support feature flags for features in GitLab via
[Flipper](https://github.com/jnunemaker/flipper/). You should use the `Feature`
class (defined in `lib/feature.rb`) in your code to get, set and list feature
flags.

During runtime you can set the values for the gates via the
[features API](../api/features.md) (accessible to admins only).

## Feature groups

Starting from GitLab 9.4 we support feature groups via
[Flipper groups](https://github.com/jnunemaker/flipper/blob/v0.10.2/docs/Gates.md#2-group).

Feature groups must be defined statically in `lib/feature.rb` (in the
`.register_feature_groups` method), but their implementation can obviously be
dynamic (querying the DB etc.).

Once defined in `lib/feature.rb`, you will be able to activate a
feature for a given feature group via the [`feature_group` param of the features API](../api/features.md#set-or-create-a-feature)

For GitLab.com, [team members have access to feature flags through Chatops](chatops_on_gitlabcom.md). Only
percentage gates are supported at this time. Setting a feature to be used 50% of
the time, you should execute `/chatops run feature set my_feature_flag 50`.

## Feature flags for user applications

This document only covers feature flags used in the development of GitLab 
itself. Feature flags in deployed user applications can be found at 
[Feature Flags](../user/project/operations/feature_flags.md)

## Developing with feature flags

In general, it's better to have a group- or user-based gate, and you should prefer
it over the use of percentage gates. This would make debugging easier, as you
filter for example logs and errors based on actors too. Furthermore, this allows
for enabling for the `gitlab-org` group first, while the rest of the users
aren't impacted.

```ruby
# Good
Feature.enabled?(:feature_flag, project)

# Avoid, if possible
Feature.enabled?(:feature_flag)
```

To use feature gates based on actors, the model needs to respond to
`flipper_id`. For example, to enable for the Foo model:

```ruby
class Foo < ActiveRecord::Base
  include FeatureGate
end
```

Features that are developed and are intended to be merged behind a feature flag
should not include a changelog entry. The entry should be added in the merge
request removing the feature flags.

In the rare case that you need the feature flag to be on automatically, use
`default_enabled: true` when checking:

```ruby
Feature.enabled?(:feature_flag, project, default_enabled: true)
```

For more information about rolling out changes using feature flags, refer to the
[Rolling out changes using feature flags](rolling_out_changes_using_feature_flags.md)
guide.

### Frontend

For frontend code you can use the method `push_frontend_feature_flag`, which is
available to all controllers that inherit from `ApplicationController`. Using
this method you can expose the state of a feature flag as follows:

```ruby
before_action do
  push_frontend_feature_flag(:vim_bindings)
end

def index
  # ...
end

def edit
  # ...
end
```

You can then check for the state of the feature flag in JavaScript as follows:

```javascript
if ( gon.features.vimBindings ) {
  // ...
}
```

The name of the feature flag in JavaScript will always be camelCased, meaning
that checking for `gon.features.vim_bindings` would not work.

### Specs

In the test environment `Feature.enabled?` is stubbed to always respond to `true`,
so we make sure behavior under feature flag doesn't go untested in some non-specific
contexts.

Whenever a feature flag is present, make sure to test _both_ states of the
feature flag.

See the
[testing guide](testing_guide/best_practices.md#feature-flags-in-tests)
for information and examples on how to stub feature flags in tests.

## Enabling a feature flag (in development)

In the rails console (`rails c`), enter the following command to enable your feature flag

```ruby
Feature.enable(:feature_flag_name)
```

## Enabling a feature flag (in production)

Check how to [roll out changes using feature flags](rolling_out_changes_using_feature_flags.md).
