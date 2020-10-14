---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Developing with feature flags

This document provides guidelines on how to use feature flags
in the GitLab codebase to conditionally enable features
and test them.

Features that are developed and merged behind a feature flag
should not include a changelog entry. The entry should be added either in the merge
request removing the feature flag or the merge request where the default value of
the feature flag is set to enabled. If the feature contains any database migrations, it
*should* include a changelog entry for the database changes.

CAUTION: **Caution:**
All newly-introduced feature flags should be [disabled by default](process.md#feature-flags-in-gitlab-development).

NOTE: **Note:**
This document is the subject of continued work as part of an epic to [improve internal usage of Feature Flags](https://gitlab.com/groups/gitlab-org/-/epics/3551). Raise any suggestions as new issues and attach them to the epic.

## Types of feature flags

Choose a feature flag type that matches the expected usage.

### `development` type

`development` feature flags are short-lived feature flags,
used so that unfinished code can be deployed in production.

A `development` feature flag should have a rollout issue,
ideally created using the [Feature Flag Roll Out template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md).

NOTE: **Note:**
This is the default type used when calling `Feature.enabled?`.

### `ops` type

`ops` feature flags are long-lived feature flags that control operational aspects
of GitLab's behavior. For example, feature flags that disable features that might
have a performance impact, like special Sidekiq worker behavior.

`ops` feature flags likely do not have rollout issues, as it is hard to
predict when they will be enabled or disabled.

To use `ops` feature flags, you must append `type: :ops` to `Feature.enabled?`
invocations:

```ruby
# Check if feature flag is enabled
Feature.enabled?(:my_ops_flag, project, type: :ops)

# Check if feature flag is disabled
Feature.disabled?(:my_ops_flag, project, type: :ops)

# Push feature flag to Frontend
push_frontend_feature_flag(:my_ops_flag, project, type: :ops)
```

### `licensed` type

`licensed` feature flags are used to temporarily disable licensed features. There
should be a one-to-one mapping of `licensed` feature flags to licensed features.

`licensed` feature flags must be `default_enabled: true`, because that's the only
supported option in the current implementation. This is under development as per
the [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/218667).

The `licensed` type has a dedicated set of functions to check if a licensed
feature is available for a project or namespace. This check validates
if the license is assigned to the namespace and feature flag itself.
The `licensed` feature flag has the same name as a licensed feature name:

```ruby
# Good: checks if feature flag is enabled
project.feature_available?(:my_licensed_feature)
namespace.feature_available?(:my_licensed_feature)

# Bad: licensed flag must be accessed via `feature_available?`
Feature.enabled?(:my_licensed_feature, type: :licensed)
push_frontend_feature_flag(:my_licensed_feature, type: :licensed)
```

## Feature flag definition and validation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229161) in GitLab 13.3.

During development (`RAILS_ENV=development`) or testing (`RAILS_ENV=test`) all feature flag usage is being strictly validated.

This process is meant to ensure consistent feature flag usage in the codebase. All feature flags **must**:

- Be known. Only use feature flags that are explicitly defined.
- Not be defined twice. They have to be defined either in FOSS or EE, but not both.
- Use a valid and consistent `type:` across all invocations.
- Use the same `default_enabled:` across all invocations.
- Have an owner.

All feature flags known to GitLab are self-documented in YAML files stored in:

- [`config/feature_flags`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/feature_flags)
- [`ee/config/feature_flags`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/feature_flags)

Each feature flag is defined in a separate YAML file consisting of a number of fields:

| Field               | Required | Description                                                    |
|---------------------|----------|----------------------------------------------------------------|
| `name`              | yes      | Name of the feature flag.                                      |
| `type`              | yes      | Type of feature flag.                                          |
| `default_enabled`   | yes      | The default state of the feature flag that is strictly validated, with `default_enabled:` passed as an argument. |
| `introduced_by_url` | no       | The URL to the Merge Request that introduced the feature flag. |
| `rollout_issue_url` | no       | The URL to the Issue covering the feature flag rollout.        |
| `group`             | no       | The [group](https://about.gitlab.com/handbook/product/product-categories/#devops-stages) that owns the feature flag. |

TIP: **Tip:**
All validations are skipped when running in `RAILS_ENV=production`.

## Create a new feature flag

The GitLab codebase provides [`bin/feature-flag`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/bin/feature-flag),
a dedicated tool to create new feature flag definitions.
The tool asks various questions about the new feature flag, then creates
a YAML definition in `config/feature_flags` or `ee/config/feature_flags`.

Only feature flags that have a YAML definition file can be used when running the development or testing environments.

```shell
$ bin/feature-flag my-feature-flag
>> Specify the group introducing the feature flag, like `group::apm`:
?> group::memory

>> URL of the MR introducing the feature flag (enter to skip):
?> https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38602

>> Open this URL and fill in the rest of the details:
https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue%5Btitle%5D=%5BFeature+flag%5D+Rollout+of+%60test-flag%60&issuable_template=Feature+Flag+Roll+Out

>> URL of the rollout issue (enter to skip):
?> https://gitlab.com/gitlab-org/gitlab/-/issues/232533
create config/feature_flags/development/test-flag.yml
---
name: test-flag
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38602
rollout_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/232533
group: group::memory
type: development
default_enabled: false
```

TIP: **Tip:**
To create a feature flag that is only used in EE, add the `--ee` flag: `bin/feature-flag --ee`

## Delete a feature flag

See [cleaning up feature flags](controls.md#cleaning-up) for more information about
deleting feature flags.

## Develop with a feature flag

There are two main ways of using Feature Flags in the GitLab codebase:

- [Backend code (Rails)](#backend)
- [Frontend code (VueJS)](#frontend)

### Backend

The feature flag interface is defined in [`lib/feature.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/feature.rb).
This interface provides a set of methods to check if the feature flag is enabled or disabled:

```ruby
if Feature.enabled?(:my_feature_flag, project)
  # execute code if feature flag is enabled
else
  # execute code if feature flag is disabled
end

if Feature.disabled?(:my_feature_flag, project)
  # execute code if feature flag is disabled
end
```

In rare cases you may want to make a feature enabled by default. If so, explain the reasoning
in the merge request. Use `default_enabled: true` when checking the feature flag state:

```ruby
if Feature.enabled?(:feature_flag, project, default_enabled: true)
  # execute code if feature flag is enabled
else
  # execute code if feature flag is disabled
end

if Feature.disabled?(:my_feature_flag, project, default_enabled: true)
  # execute code if feature flag is disabled
end
```

If not specified, the default feature flag type for `Feature.enabled?` and `Feature.disabled?`
is `type: development`. For all other feature flag types, you must specify the `type:`:

```ruby
if Feature.enabled?(:feature_flag, project, type: :ops)
  # execute code if ops feature flag is enabled
else
  # execute code if ops feature flag is disabled
end

if Feature.disabled?(:my_feature_flag, project, type: :ops)
  # execute code if feature flag is disabled
end
```

### Frontend

Use the `push_frontend_feature_flag` method for frontend code, which is
available to all controllers that inherit from `ApplicationController`. You can use
this method to expose the state of a feature flag, for example:

```ruby
before_action do
  # Prefer to scope it per project or user e.g.
  push_frontend_feature_flag(:vim_bindings, project)
end

def index
  # ...
end

def edit
  # ...
end
```

You can then check the state of the feature flag in JavaScript as follows:

```javascript
if ( gon.features.vimBindings ) {
  // ...
}
```

The name of the feature flag in JavaScript is always camelCase,
so checking for `gon.features.vim_bindings` would not work.

See the [Vue guide](../fe_guide/vue.md#accessing-feature-flags) for details about
how to access feature flags in a Vue component.

In rare cases you may want to make a feature enabled by default. If so, explain the reasoning
in the merge request. Use `default_enabled: true` when checking the feature flag state:

```ruby
before_action do
  # Prefer to scope it per project or user e.g.
  push_frontend_feature_flag(:vim_bindings, project, default_enabled: true)
end
```

If not specified, the default feature flag type for `push_frontend_feature_flag`
is `type: development`. For all other feature flag types, you must specify the `type:`:

```ruby
before_action do
  push_frontend_feature_flag(:vim_bindings, project, type: :ops)
end
```

### Feature actors

**It is strongly advised to use actors with feature flags.** Actors provide a simple
way to enable a feature flag only for a given project, group or user. This makes debugging
easier, as you can filter logs and errors for example, based on actors. This also makes it possible
to enable the feature on the `gitlab-org` or `gitlab-com` groups first, while the rest of
the users aren't impacted.

Actors also provide an easy way to do a percentage rollout of a feature in a sticky way.
If a 1% rollout enabled a feature for a specific actor, that actor will continue to have the feature enabled at
10%, 50%, and 100%.

GitLab currently supports the following models as feature flag actors:

- `User`
- `Project`
- `Group`

The actor is a second parameter of the `Feature.enabled?` call. The
same actor type must be used consistently for all invocations of `Feature.enabled?`.

```ruby
Feature.enabled?(:feature_flag, project)
Feature.enabled?(:feature_flag, group)
Feature.enabled?(:feature_flag, user)
```

### Enable additional objects as actors

To use feature gates based on actors, the model needs to respond to
`flipper_id`. For example, to enable for the Foo model:

```ruby
class Foo < ActiveRecord::Base
  include FeatureGate
end
```

Only models that `include FeatureGate` or expose `flipper_id` method can be
used as an actor for `Feature.enabled?`.

### Feature flags for licensed features

If a feature is license-gated, there's no need to add an additional
explicit feature flag check since the flag is checked as part of the
`License.feature_available?` call. Similarly, there's no need to "clean up" a
feature flag once the feature has reached general availability.

The [`Project#feature_available?`](https://gitlab.com/gitlab-org/gitlab/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/app/models/project_feature.rb#L63-68),
[`Namespace#feature_available?`](https://gitlab.com/gitlab-org/gitlab/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/ee/app/models/ee/namespace.rb#L71-85) (EE), and
[`License.feature_available?`](https://gitlab.com/gitlab-org/gitlab/blob/4cc1c62918aa4c31750cb21dfb1a6c3492d71080/ee/app/models/license.rb#L293-300) (EE) methods all implicitly check for
a by default enabled feature flag with the same name as the provided argument.

**An important side-effect of the implicit feature flags mentioned above is that
unless the feature is explicitly disabled or limited to a percentage of users,
the feature flag check defaults to `true`.**

NOTE: **Note:**
Due to limitations with `feature_available?`, the YAML definition for `licensed` feature
flags accepts only `default_enabled: true`. This is under development as per the
[related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/218667).

#### Alpha/beta licensed feature flags

This is relevant when developing the feature using
[several smaller merge requests](https://about.gitlab.com/handbook/values/#make-small-merge-requests), or when the feature is considered to be an
[alpha or beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#alpha-beta-ga), and
should not be available by default.

As an example, if you were to ship the frontend half of a feature without the
backend, you'd want to disable the feature entirely until the backend half is
also ready to be shipped. To make sure this feature is disabled for both
GitLab.com and self-managed instances, you should use the
[`Namespace#alpha_feature_available?`](https://gitlab.com/gitlab-org/gitlab/blob/458749872f4a8f27abe8add930dbb958044cb926/ee/app/models/ee/namespace.rb#L113) or
[`Namespace#beta_feature_available?`](https://gitlab.com/gitlab-org/gitlab/blob/458749872f4a8f27abe8add930dbb958044cb926/ee/app/models/ee/namespace.rb#L100-112)
method, according to our [definitions](https://about.gitlab.com/handbook/product/gitlab-the-product/#alpha-beta-ga). This ensures the feature is disabled unless the feature flag is
_explicitly_ enabled.

CAUTION: **Caution:**
If `alpha_feature_available?` or `beta_feature_available?` is used, the YAML definition
for the feature flag must use `default_enabled: [false, true]`, because the usage
of the feature flag is undefined. These methods may change, as per the
[related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/218667).

The resulting YAML should be similar to:

```yaml
name: scoped_labels
group: group::memory
type: licensed
# The `default_enabled:` is undefined
# as `feature_available?` uses `default_enabled: true`
# as `beta_feature_available?` uses `default_enabled: false`
default_enabled: [false, true]
```

### Feature groups

Feature groups must be defined statically in `lib/feature.rb` (in the
`.register_feature_groups` method), but their implementation can obviously be
dynamic (querying the DB, for example).

Once defined in `lib/feature.rb`, you can to activate a
feature for a given feature group via the [`feature_group` parameter of the features API](../../api/features.md#set-or-create-a-feature)

### Enabling a feature flag locally (in development)

In the rails console (`rails c`), enter the following command to enable a feature flag:

```ruby
Feature.enable(:feature_flag_name)
```

Similarly, the following command disables a feature flag:

```ruby
Feature.disable(:feature_flag_name)
```

You can also enable a feature flag for a given gate:

```ruby
Feature.enable(:feature_flag_name, Project.find_by_full_path("root/my-project"))
```

## Feature flags in tests

Introducing a feature flag into the codebase creates an additional code path that should be tested.
It is strongly advised to test all code affected by a feature flag, both when **enabled** and **disabled**
to ensure the feature works properly.

NOTE: **Note:**
When using the testing environment, all feature flags are enabled by default.

To disable a feature flag in a test, use the `stub_feature_flags`
helper. For example, to globally disable the `ci_live_trace` feature
flag in a test:

```ruby
stub_feature_flags(ci_live_trace: false)

Feature.enabled?(:ci_live_trace) # => false
```

If you wish to set up a test where a feature flag is enabled only
for some actors and not others, you can specify this in options
passed to the helper. For example, to enable the `ci_live_trace`
feature flag for a specific project:

```ruby
project1, project2 = build_list(:project, 2)

# Feature will only be enabled for project1
stub_feature_flags(ci_live_trace: project1)

Feature.enabled?(:ci_live_trace) # => false
Feature.enabled?(:ci_live_trace, project1) # => true
Feature.enabled?(:ci_live_trace, project2) # => false
```

The behavior of FlipperGate is as follows:

1. You can enable an override for a specified actor to be enabled.
1. You can disable (remove) an override for a specified actor,
   falling back to the default state.
1. There's no way to model that you explicitly disabled a specified actor.

```ruby
Feature.enable(:my_feature)
Feature.disable(:my_feature, project1)
Feature.enabled?(:my_feature) # => true
Feature.enabled?(:my_feature, project1) # => true

Feature.disable(:my_feature2)
Feature.enable(:my_feature2, project1)
Feature.enabled?(:my_feature2) # => false
Feature.enabled?(:my_feature2, project1) # => true
```

### `have_pushed_frontend_feature_flags`

Use `have_pushed_frontend_feature_flags` to test if [`push_frontend_feature_flag`](#frontend)
has added the feature flag to the HTML.

For example,

```ruby
stub_feature_flags(value_stream_analytics_path_navigation: false)

visit group_analytics_cycle_analytics_path(group)

expect(page).to have_pushed_frontend_feature_flags(valueStreamAnalyticsPathNavigation: false)
```

### `stub_feature_flags` vs `Feature.enable*`

It is preferred to use `stub_feature_flags` to enable feature flags
in the testing environment. This method provides a simple and well described
interface for simple use cases.

However, in some cases more complex behavior needs to be tested,
like percentage rollouts of feature flags. This can be done using
`.enable_percentage_of_time` or `.enable_percentage_of_actors`:

```ruby
# Good: feature needs to be explicitly disabled, as it is enabled by default if not defined
stub_feature_flags(my_feature: false)
stub_feature_flags(my_feature: true)
stub_feature_flags(my_feature: project)
stub_feature_flags(my_feature: [project, project2])

# Bad
Feature.enable(:my_feature_2)

# Good: enable my_feature for 50% of time
Feature.enable_percentage_of_time(:my_feature_3, 50)

# Good: enable my_feature for 50% of actors/gates/things
Feature.enable_percentage_of_actors(:my_feature_4, 50)
```

Each feature flag that has a defined state is persisted
during test execution time:

```ruby
Feature.persisted_names.include?('my_feature') => true
Feature.persisted_names.include?('my_feature_2') => true
Feature.persisted_names.include?('my_feature_3') => true
Feature.persisted_names.include?('my_feature_4') => true
```

### Stubbing actor

When you want to enable a feature flag for a specific actor only,
you can stub its representation. A gate that is passed
as an argument to `Feature.enabled?` and `Feature.disabled?` must be an object
that includes `FeatureGate`.

In specs you can use the `stub_feature_flag_gate` method that allows you to
quickly create a custom actor:

```ruby
gate = stub_feature_flag_gate('CustomActor')

stub_feature_flags(ci_live_trace: gate)

Feature.enabled?(:ci_live_trace) # => false
Feature.enabled?(:ci_live_trace, gate) # => true
```

You can also disable a feature flag for a specific actor:

```ruby
gate = stub_feature_flag_gate('CustomActor')

stub_feature_flags(ci_live_trace: false, thing: gate)
```

### Controlling feature flags engine in tests

Our Flipper engine in the test environment works in a memory mode `Flipper::Adapters::Memory`.
`production` and `development` modes use `Flipper::Adapters::ActiveRecord`.

You can control whether the `Flipper::Adapters::Memory` or `ActiveRecord` mode is being used.

#### `stub_feature_flags: true` (default and preferred)

In this mode Flipper is configured to use `Flipper::Adapters::Memory` and mark all feature
flags to be on-by-default and persisted on a first use. This overwrites the `default_enabled:`
of `Feature.enabled?` and `Feature.disabled?` returning always `true` unless feature flag
is persisted.

Make sure behavior under feature flag doesn't go untested in some non-specific contexts.

See the
[testing guide](../testing_guide/best_practices.md#feature-flags-in-tests)
for information and examples on how to stub feature flags in tests.

### `stub_feature_flags: false`

This disables a memory-stubbed flipper, and uses `Flipper::Adapters::ActiveRecord`
a mode that is used by `production` and `development`.

You should use this mode only when you really want to tests aspects of Flipper
with how it interacts with `ActiveRecord`.
