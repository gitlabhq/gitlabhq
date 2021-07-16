---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Feature flags in the development of GitLab

**NOTE**:
The documentation below covers feature flags used by GitLab to deploy its own features, which **is not** the same
as the [feature flags offered as part of the product](../../operations/feature_flags.md).

This document provides guidelines on how to use feature flags
for the development of GitLab to conditionally and/or incrementally enable features
and test them in production/staging.

WARNING:
All newly-introduced feature flags should be [disabled by default](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#feature-flags-in-gitlab-development).

NOTE:
This document is the subject of continued work as part of an epic to [improve internal usage of Feature Flags](https://gitlab.com/groups/gitlab-org/-/epics/3551). Raise any suggestions as new issues and attach them to the epic.

For an [overview of the feature flag lifecycle](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#feature-flag-lifecycle), or if you need help deciding [if you should use a feature flag](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags) or not, please see the [feature flag lifecycle](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle) handbook page.

## When to use feature flags

Moved to the ["When to use feature flags"](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags) section in the handbook.

## Feature flags in GitLab development

The following highlights should be considered when deciding if feature flags
should be leveraged:

- The feature flag must be **disabled by default**.
- Feature flags should remain in the codebase for as short period as possible
  to reduce the need for feature flag accounting.
- The person operating the feature flag is responsible for clearly communicating
  the status of a feature behind the feature flag in the documentation and with other stakeholders. The
  issue description should be updated with the feature flag name and whether it is
  defaulted on or off as soon it is evident that a feature flag is needed.
- Merge requests that introduce a feature flag, update its state, or remove them
  existing feature flag because a feature is deemed stable must have the
  ~"feature flag" label assigned.

When the feature implementation is delivered among multiple merge requests:

  1. [Create a new feature flag](#create-a-new-feature-flag)
     which is **off** by default, in the first merge request which uses the flag.
     Flags [should not be added separately](#risk-of-a-broken-main-branch).
  1. Submit incremental changes via one or more merge requests, ensuring that any
     new code added can only be reached if the feature flag is **on**.
     You can keep the feature flag enabled on your local GDK during development.
  1. When the feature is ready to be tested, enable the feature flag for
     a specific project and ensure that there are no issues with the implementation.
  1. When the feature is ready to be announced, create a merge request that adds
     documentation about the feature, including [documentation for the feature flag itself](../documentation/feature_flags.md),
     and a [changelog entry](#changelog). In the same merge request either flip the feature flag to
     be **on by default** or remove it entirely in order to enable the new behavior.

One might be tempted to think that feature flags will delay the release of a
feature by at least one month (= one release). This is not the case. A feature
flag does not have to stick around for a specific amount of time
(e.g. at least one release), instead they should stick around until the feature
is deemed stable. Stable means it works on GitLab.com without causing any
problems, such as outages.

## Risk of a broken main branch

Feature flags must be used in the MR that introduces them. Not doing so causes a
[broken main branch](https://about.gitlab.com/handbook/engineering/workflow/#broken-master) scenario due
to the `rspec:feature-flags` job that only runs on the `main` branch.

## Types of feature flags

Choose a feature flag type that matches the expected usage.

### `development` type

`development` feature flags are short-lived feature flags,
used for deploying unfinished code to production. Most feature flags used at
GitLab are the `development` type.

A `development` feature flag must have a rollout issue
created from the [Feature Flag Roll Out template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md).

The format for `development` feature flags is `Feature.<state>(:<dev_flag_name>)`.
To enable and disable them, run on the GitLab Rails console:

```ruby
# To enable it for the instance:
Feature.enable(:<dev_flag_name>)

# To disable it for the instance:
Feature.disable(:<dev_flag_name>)

# To enable for a specific project:
Feature.enable(:<dev_flag_name>, Project.find(<project id>))

# To disable for a specific project:
Feature.disable(:<dev_flag_name>, Project.find(<project id>))
```

To check a `development` feature flag's state:

```ruby
# Check if the feature flag is enabled
Feature.enabled?(:dev_flag_name)

# Check if the feature flag is disabled
Feature.disabled?(:dev_flag_name)
```

For `development` feature flags, the type doesn't need to be specified (they're the default type).

### `ops` type

`ops` feature flags are long-lived feature flags that control operational aspects
of GitLab product behavior. For example, feature flags that disable features that might
have a performance impact such as Sidekiq worker behavior.

`ops` feature flags likely do not have rollout issues, as it is hard to
predict when they are enabled or disabled.

To invoke `ops` feature flags, you must append `type: :ops`:

```ruby
# Check if feature flag is enabled
Feature.enabled?(:my_ops_flag, project, type: :ops)

# Check if feature flag is disabled
Feature.disabled?(:my_ops_flag, project, type: :ops)

# Push feature flag to Frontend
push_frontend_feature_flag(:my_ops_flag, project, type: :ops)
```

### `experiment` type

`experiment` feature flags are used for A/B testing on GitLab.com.

An `experiment` feature flag should conform to the same standards as a `development` feature flag,
although the interface has some differences. An experiment feature flag should have a rollout issue,
created using the [Experiment Tracking template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/experiment_tracking_template.md). More information can be found in the [experiment guide](../experiment_guide/index.md).

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
| `group`             | no       | The [group](https://about.gitlab.com/handbook/product/categories/#devops-stages) that owns the feature flag. |

NOTE:
All validations are skipped when running in `RAILS_ENV=production`.

## Create a new feature flag

The GitLab codebase provides [`bin/feature-flag`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/bin/feature-flag),
a dedicated tool to create new feature flag definitions.
The tool asks various questions about the new feature flag, then creates
a YAML definition in `config/feature_flags` or `ee/config/feature_flags`.

Only feature flags that have a YAML definition file can be used when running the development or testing environments.

```shell
$ bin/feature-flag my_feature_flag
>> Specify the group introducing the feature flag, like `group::apm`:
?> group::memory

>> URL of the MR introducing the feature flag (enter to skip):
?> https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38602

>> Open this URL and fill in the rest of the details:
https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue%5Btitle%5D=%5BFeature+flag%5D+Rollout+of+%60test-flag%60&issuable_template=Feature+Flag+Roll+Out

>> URL of the rollout issue (enter to skip):
?> https://gitlab.com/gitlab-org/gitlab/-/issues/232533
create config/feature_flags/development/my_feature_flag.yml
---
name: my_feature_flag
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38602
rollout_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/232533
group: group::memory
type: development
default_enabled: false
```

All newly-introduced feature flags must be [**disabled by default**](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#feature-flags-in-gitlab-development).

Features that are developed and merged behind a feature flag
should not include a changelog entry. The entry should be added either in the merge
request removing the feature flag or the merge request where the default value of
the feature flag is set to enabled. If the feature contains any database migrations, it
*should* include a changelog entry for the database changes.

NOTE:
To create a feature flag that is only used in EE, add the `--ee` flag: `bin/feature-flag --ee`

### Risk of a broken master (main) branch

WARNING:
Feature flags **must** be used in the MR that introduces them. Not doing so causes a
[broken master](https://about.gitlab.com/handbook/engineering/workflow/#broken-master) scenario due
to the `rspec:feature-flags` job that only runs on the `master` branch.

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

If not specified, `default_enabled` is `false`.

To force reading the `default_enabled` value from the relative YAML definition file, use
`default_enabled: :yaml`:

```ruby
if Feature.enabled?(:feature_flag, project, default_enabled: :yaml)
  # execute code if feature flag is enabled
end
```

```ruby
if Feature.disabled?(:feature_flag, project, default_enabled: :yaml)
  # execute code if feature flag is disabled
end
```

This allows to use the same feature flag check across various parts of the codebase and
maintain the status of `default_enabled` in the YAML definition file which is the SSOT.

If `default_enabled: :yaml` is used, a YAML definition is expected or an error is raised
in development or test environment, while returning `false` on production.

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

WARNING:
Don't use feature flags at application load time. For example, using the `Feature` class in
`config/initializers/*` or at the class level could cause an unexpected error. This error occurs
because a database that a feature flag adapter might depend on doesn't exist at load time
(especially for fresh installations). Checking for the database's existence at the caller isn't
recommended, as some adapters don't require a database at all (for example, the HTTP adapter). The
feature flag setup check must be abstracted in the `Feature` namespace. This approach also requires
application reload when the feature flag changes. You must therefore ask SREs to reload the
Web/API/Sidekiq fleet on production, which takes time to fully rollout/rollback the changes. For
these reasons, use environment variables (for example, `ENV['YOUR_FEATURE_NAME']`) or `gitlab.yml`
instead.

Here's an example of a pattern that you should avoid:

```ruby
class MyClass
  if Feature.enabled?(:...)
    new_process
  else
    legacy_process
  end
end
```

### Frontend

When using a feature flag for UI elements, make sure to _also_ use a feature
flag for the underlying backend code, if there is any. This ensures there is
absolutely no way to use the feature until it is enabled.

Use the `push_frontend_feature_flag` method which is available to all controllers that inherit from `ApplicationController`. You can use this method to expose the state of a feature flag, for example:

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

Please see [Feature flag controls](controls.md#process) for more details on working with feature flags.

#### Selectively disable by actor

By default you cannot selectively disable a feature flag by actor.

```shell
# This will not work how you would expect.
/chatops run feature set some_feature true
/chatops run feature set --project=gitlab-org/gitlab some_feature false
```

However, if you add two feature flags, you can write your conditional statement in such a way that the equivalent selective disable is possible.

```ruby
Feature.enabled?(:a_feature, project) && Feature.disabled?(:a_feature_override, project)
```

```shell
# This will enable a feature flag globally, except for gitlab-org/gitlab
/chatops run feature set a_feature true
/chatops run feature set --project=gitlab-org/gitlab a_feature_override true
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

You can't use a feature flag with the same name as a licensed feature name, because
it would cause a naming collision. This was [widely discussed and removed](https://gitlab.com/gitlab-org/gitlab/-/issues/259611)
because it is confusing.

To check for licensed features, add a dedicated feature flag under a different name
and check it explicitly, for example:

```ruby
Feature.enabled?(:licensed_feature_feature_flag, project) &&
  project.feature_available?(:licensed_feature)
```

### Feature groups

Feature groups must be defined statically in `lib/feature.rb` (in the
`.register_feature_groups` method), but their implementation can be
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

### Removing a feature flag locally (in development)

When manually enabling or disabling a feature flag from the Rails console, its default value gets overwritten.
This can cause confusion when changing the flag's `default_enabled` attribute.

To reset the feature flag to the default status, you can remove it in the rails console (`rails c`)
as follows:

```ruby
Feature.remove(:feature_flag_name)
```

## Changelog

- Any change behind a feature flag **disabled** by default **should not** have a changelog entry.
  - **Exception:** database migrations **should** have a changelog entry.
- Any change related to a feature flag itself (flag removal, default-on setting) **should** have a changelog entry.
  Use the flowchart to determine the changelog entry type.

  ```mermaid
  graph LR
      A[flag: default off] -->|'added' / 'changed'| B(flag: default on)
      B -->|'other'| C(remove flag, keep new code)
      B -->|'removed' / 'changed'| D(remove flag, keep old code)
      A -->|'added' / 'changed'| C
      A -->|no changelog| D
  ```

- Any change behind a feature flag that is **enabled** by default **should** have a changelog entry.

## Feature flags in tests

Introducing a feature flag into the codebase creates an additional code path that should be tested.
It is strongly advised to test all code affected by a feature flag, both when **enabled** and **disabled**
to ensure the feature works properly.

When using the testing environment, all feature flags are enabled by default.

WARNING:
This does not apply to end-to-end (QA) tests, which [do not disable feature flags by default](#end-to-end-qa-tests). There is a different [process for using feature flags in end-to-end tests](../testing_guide/end_to_end/feature_flags.md).

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

### `stub_feature_flags: false`

This disables a memory-stubbed flipper, and uses `Flipper::Adapters::ActiveRecord`
a mode that is used by `production` and `development`.

You should use this mode only when you really want to tests aspects of Flipper
with how it interacts with `ActiveRecord`.

### End-to-end (QA) tests

Toggling feature flags works differently in end-to-end (QA) tests. The end-to-end test framework does not have direct access to
Rails or the database, so it can't use Flipper. Instead, it uses [the public API](../../api/features.md#set-or-create-a-feature). Each end-to-end test can [enable or disable a feature flag during the test](../testing_guide/end_to_end/feature_flags.md). Alternatively, you can enable or disable a feature flag before one or more tests when you [run them from your GitLab repository's `qa` directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa#running-tests-with-a-feature-flag-enabled-or-disabled), or if you [run the tests via GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#running-tests-with-a-feature-flag-enabled).

[As noted above, feature flags are not enabled by default in end-to-end tests.](#feature-flags-in-tests)
This means that end-to-end tests will run with feature flags in the default state implemented in the source
code, or with the feature flag in its current state on the GitLab instance under test, unless the
test is written to enable/disable a feature flag explicitly.

When a feature flag is changed on Staging or on GitLab.com, a Slack message will be posted to the `#qa-staging` or `#qa-production` channels to inform
the pipeline triage DRI so that they can more easily determine if any failures are related to a feature flag change. However, if you are working on a change you can
help to avoid unexpected failures by [confirming that the end-to-end tests pass with a feature flag enabled.](../testing_guide/end_to_end/feature_flags.md#confirming-that-end-to-end-tests-pass-with-a-feature-flag-enabled)
