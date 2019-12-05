# Developing with feature flags

In general, it's better to have a group- or user-based gate, and you should prefer
it over the use of percentage gates. This would make debugging easier, as you
filter for example logs and errors based on actors too. Furthermore, this allows
for enabling for the `gitlab-org` or `gitlab-com` group first, while the rest of
the users aren't impacted.

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
request removing the feature flag. If the feature contains any DB migration it
should include a changelog entry for DB changes.

In the rare case that you need the feature flag to be on automatically, use
`default_enabled: true` when checking:

```ruby
Feature.enabled?(:feature_flag, project, default_enabled: true)
```

The [`Project#feature_available?`][project-fa],
[`Namespace#feature_available?`][namespace-fa] (EE), and
[`License.feature_available?`][license-fa] (EE) methods all implicitly check for
a feature flag by the same name as the provided argument.

For example if a feature is license-gated, there's no need to add an additional
explicit feature flag check since the flag will be checked as part of the
`License.feature_available?` call. Similarly, there's no need to "clean up" a
feature flag once the feature has reached general availability.

You'd still want to use an explicit `Feature.enabled?` check if your new feature
isn't gated by a License or Plan.

[project-fa]: https://gitlab.com/gitlab-org/gitlab/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/app/models/project_feature.rb#L63-68
[namespace-fa]: https://gitlab.com/gitlab-org/gitlab/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/ee/app/models/ee/namespace.rb#L71-85
[license-fa]: https://gitlab.com/gitlab-org/gitlab/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/ee/app/models/license.rb#L293-300

**An important side-effect of the implicit feature flags mentioned above is that
unless the feature is explicitly disabled or limited to a percentage of users,
the feature flag check will default to `true`.**

As an example, if you were to ship the backend half of a feature behind a flag,
you'd want to explicitly disable that flag until the frontend half is also ready
to be shipped. To make sure this feature is disabled for both GitLab.com and
self-managed instances you'd need to explicitly call `Feature.enabled?` method
before the `feature_available` method. This ensures the feature_flag is defaulting
to `false`.

## Feature groups

Starting from GitLab 9.4 we support feature groups via
[Flipper groups](https://github.com/jnunemaker/flipper/blob/v0.10.2/docs/Gates.md#2-group).

Feature groups must be defined statically in `lib/feature.rb` (in the
`.register_feature_groups` method), but their implementation can obviously be
dynamic (querying the DB etc.).

Once defined in `lib/feature.rb`, you will be able to activate a
feature for a given feature group via the [`feature_group` param of the features API](../../api/features.md#set-or-create-a-feature)

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

See the [Vue guide](../fe_guide/vue.md#accessing-feature-flags) for details about
how to access feature flags in a Vue component.

### Specs

In the test environment `Feature.enabled?` is stubbed to always respond to `true`,
so we make sure behavior under feature flag doesn't go untested in some non-specific
contexts.

Whenever a feature flag is present, make sure to test _both_ states of the
feature flag.

See the
[testing guide](../testing_guide/best_practices.md#feature-flags-in-tests)
for information and examples on how to stub feature flags in tests.

### Enabling a feature flag (in development)

In the rails console (`rails c`), enter the following command to enable your feature flag

```ruby
Feature.enable(:feature_flag_name)
```

Similarly, the following command will disable a feature flag:

```ruby
Feature.disable(:feature_flag_name)
```
