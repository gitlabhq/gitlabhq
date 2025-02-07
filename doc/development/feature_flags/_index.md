---
stage: none
group: unassigned
info: "See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
title: Feature flags in the development of GitLab
---

NOTE:
This document explains how to contribute to the development and operations of the GitLab product.
If you want to use feature flags to show and hide functionality in your own applications,
view [this feature flags information](../../operations/feature_flags.md) instead.

WARNING:
All newly-introduced feature flags should be [disabled by default](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/).

WARNING:
All newly-introduced feature flags should be [used with an actor](controls.md#percentage-based-actor-selection).

Design documents:

- (Latest) [Feature Flags usage in GitLab development and operations](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/feature_flags_usage_in_dev_and_ops/)
- [Development Feature Flags Architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/feature_flags_development/)

This document is the subject of continued work as part of an epic to [improve internal usage of feature flags](https://gitlab.com/groups/gitlab-org/-/epics/3551). Raise any suggestions as new issues and attach them to the epic.

For an [overview of the feature flag lifecycle](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#feature-flag-lifecycle), or if you need help deciding [if you should use a feature flag](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags) or not, see the feature flag lifecycle handbook page.

## When to use feature flags

Moved to the ["When to use feature flags"](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags) section in the handbook.

### Do not use feature flags for long lived settings

Feature flags are meant to be short lived. If you are intending on adding a
feature flag so that something can be enabled per user/group/project for a long
period of time, consider introducing
[Cascading Settings](../cascading_settings.md) or [Application Settings](../application_settings.md)
instead. Settings
offer a way for customers to enable or disable features for themselves on
GitLab.com or self-managed and can remain in the codebase as long as needed. In
contrast users have no way to enable or disable feature flags for themselves on
GitLab.com and only self-managed admins can change the feature flags.
Also note that
[feature flags are not supported in GitLab Dedicated](../enabling_features_on_dedicated.md#feature-flags)
which is another reason you should not use them as a replacement for settings.

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
- Merge requests that introduce a feature flag, update its state, or remove the
  existing feature flag because a feature is deemed stable must have the
  ~"feature flag" label assigned.

When the feature implementation is delivered over multiple merge requests:

1. [Create a new feature flag](#create-a-new-feature-flag)
   which is **disabled** by default, in the first merge request which uses the flag.
   Flags [should not be added separately](#risk-of-a-broken-default-branch).
1. Submit incremental changes via one or more merge requests, ensuring that any
   new code added can only be reached if the feature flag is **enabled**.
   You can keep the feature flag enabled on your local GDK during development.
1. When the feature is ready to be tested by other team members, [create the initial documentation](../documentation/feature_flags.md#when-to-document-features-behind-a-feature-flag).
   Include details about the status of the [feature flag](../documentation/feature_flags.md#how-to-add-feature-flag-documentation).
1. Enable the feature flag for a specific group/project/user and ensure that there are no issues
   with the implementation. Do not enable the feature flag for a public project
   like `gitlab-org/gitlab` if there is no documentation. Team members and contributors might search for
   documentation on how to use the feature if they see it enabled in a public project.
1. When the feature is ready for production use, including self-managed instances, open one merge request to:
   - Update the documentation to describe the latest flag status.
   - Add a [changelog entry](#changelog).
   - Remove the feature flag to enable the new behavior, or flip the feature flag to be **enabled by default** (only for `ops` and `beta` feature flags).

When the feature flag removal is delivered over multiple merge requests:

1. The value change of a feature flag should be the only change in a merge request. As long as the feature flag exists in the codebase, both states should be fully functional (when the feature is on and off).
1. After all mentions of the feature flag have been removed, legacy code can be removed. Steps in the feature flag roll-out issue should be followed, and if a step needs to be skipped, a comment should be added to the issue detailing why.

One might be tempted to think that feature flags will delay the release of a
feature by at least one month (= one release). This is not the case. A feature
flag does not have to stick around for a specific amount of time
(for example, at least one release), instead they should stick around until the feature
is deemed stable. **Stable means it works on GitLab.com without causing any
problems, such as outages.**

## Risk of a broken default branch

Feature flags must be used in the MR that introduces them. Not doing so causes a
[broken default branch](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master) scenario due
to the `rspec:feature-flags` job that only runs on the default branch.

## Types of feature flags

Choose a feature flag type that matches the expected usage.

### `gitlab_com_derisk` type

`gitlab_com_derisk` feature flags are short-lived feature flags,
used to de-risk GitLab.com deployments. Most feature flags used at
GitLab are of the `gitlab_com_derisk` type.

#### Constraints

- `default_enabled`: **Must not** be set to true. This kind of feature flag is meant to lower the risk on GitLab.com, thus there's no need to keep the flag in the codebase after it's been enabled on GitLab.com. `default_enabled: true` will not have any effect for this type of feature flag.
- Maximum Lifespan: 2 months after it's merged into the default branch
- Documentation: This type of feature flag doesn't need to be documented in the
  [All feature flags in GitLab](../../user/feature_flags.md) page given they're short-lived and deployment-related
- Rollout issue: **Must** have a rollout issue created from the
  [Feature flag Roll Out template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md)

#### Usage

The format for `gitlab_com_derisk` feature flags is `Feature.<state>(:<dev_flag_name>)`.

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

To check a `gitlab_com_derisk` feature flag's state:

```ruby
# Check if the feature flag is enabled
Feature.enabled?(:dev_flag_name)

# Check if the feature flag is disabled
Feature.disabled?(:dev_flag_name)
```

### `wip` type

Some features are complex and need to be implemented through several MRs. Until they're fully implemented,
it needs to be hidden from anyone. In that case, the `wip` (for "Work In Progress") feature flag allows
to merge all the changes to the main branch without actually using the feature yet.

Once the feature is complete, the feature flag type can be changed to the `gitlab_com_derisk` or
`beta` type depending on how the feature will be presented/documented to customers.

#### Constraints

- `default_enabled`: **Must not** be set to true. If needed, this type can be changed to beta once the feature is complete.
- Maximum Lifespan: 4 months after it's merged into the default branch
- Documentation: This type of feature flag doesn't need to be documented in the
  [All feature flags in GitLab](../../user/feature_flags.md) page given they're mostly hiding unfinished code
- Rollout issue: Likely no need for a rollout issues, as `wip` feature flags should be transitioned to
  another type before being enabled

#### Usage

```ruby
# Check if feature flag is enabled
Feature.enabled?(:my_wip_flag, project)

# Check if feature flag is disabled
Feature.disabled?(:my_wip_flag, project)

# Push feature flag to Frontend
push_frontend_feature_flag(:my_wip_flag, project)
```

### `beta` type

We might [not be confident we'll be able to scale, support, and maintain a feature](../../policy/development_stages_support.md) in its current form for every designed use case ([example](https://gitlab.com/gitlab-org/gitlab/-/issues/336070#note_1523983444)).
There are also scenarios where a feature is not complete enough to be considered an MVC.
Providing a flag in this case allows engineers and customers to disable the new feature until it's performant enough.

#### Constraints

- `default_enabled`: Can be set to `true` so that a feature can be "released" to everyone in beta with the
  possibility to disable it in the case of scalability issues (ideally it should only be disabled for this
  reason on specific on-premise installations)
- Maximum Lifespan: 6 months after it's merged into the default branch
- Documentation: This type of feature flag **must** be documented in the
  [All feature flags in GitLab](../../user/feature_flags.md) page
- Rollout issue: **Must** have a rollout issue
  created from the
  [Feature flag Roll Out template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md)

#### Usage

```ruby
# Check if feature flag is enabled
Feature.enabled?(:my_beta_flag, project)

# Check if feature flag is disabled
Feature.disabled?(:my_beta_flag, project)

# Push feature flag to Frontend
push_frontend_feature_flag(:my_beta_flag, project)
```

### `ops` type

`ops` feature flags are long-lived feature flags that control operational aspects
of GitLab product behavior. For example, feature flags that disable features that might
have a performance impact such as Sidekiq worker behavior.

Remember that using this type should follow a conscious decision not to introduce an
instance/group/project/user setting.

While `ops` type flags have an unlimited lifespan, every 12 months, they must be evaluated to determine if
they are still necessary.

#### Constraints

- `default_enabled`: Should be set to `false` in most cases, and only enabled to resolve temporary scalability
  issues or help debug production issues.
- Maximum Lifespan: Unlimited, but must be evaluated every 12 months
- Documentation: This type of feature flag **must** be documented in the
  [All feature flags in GitLab](../../user/feature_flags.md) page as well as be associated with an operational
  runbook describing the circumstances when it can be used.
- Rollout issue: Likely no need for a rollout issues, as it is hard to predict when they are enabled or disabled

#### Usage

```ruby
# Check if feature flag is enabled
Feature.enabled?(:my_ops_flag, project)

# Check if feature flag is disabled
Feature.disabled?(:my_ops_flag, project)

# Push feature flag to Frontend
push_frontend_feature_flag(:my_ops_flag, project)
```

### `experiment` type

`experiment` feature flags are used for A/B testing on GitLab.com.

An `experiment` feature flag should conform to the same standards as a `beta` feature flag,
although the interface has some differences. An experiment feature flag should have a rollout issue,
created using the [Experiment tracking template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Experiment%20Rollout.md). More information can be found in the [experiment guide](../experiment_guide/_index.md).

#### Constraints

- `default_enabled`: **Must not** be set to `true`.
- Maximum Lifespan: 6 months after it's merged into the default branch

### `worker` type

`worker` feature flags are special `ops` flags that allow to control Sidekiq workers behavior, such as deferring Sidekiq jobs.

`worker` feature flags likely do not have any YAML definition as the name could be dynamically generated using
the worker name itself, for example, `run_sidekiq_jobs_AuthorizedProjectsWorker`. Some examples for using `worker` type feature
flags can be found in [deferring Sidekiq jobs](#deferring-sidekiq-jobs).

### (Deprecated) `development` type

The `development` type is deprecated in favor of the `gitlab_com_derisk`, `wip`, and `beta` feature flag types.

## Feature flag definition and validation

During development (`RAILS_ENV=development`) or testing (`RAILS_ENV=test`) all feature flag usage is being strictly validated.

This process is meant to ensure consistent feature flag usage in the codebase. All feature flags **must**:

- Be known. Only use feature flags that are explicitly defined (except for feature flags of the types `experiment`, `worker` and `undefined`).
- Not be defined twice. They have to be defined either in FOSS or EE, but not both.
- For feature flags that don't have a definition file, use a valid and consistent `type:` across all invocations.
- Have an owner.

All feature flags known to GitLab are self-documented in YAML files stored in:

- [`config/feature_flags`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/feature_flags)
- [`ee/config/feature_flags`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/feature_flags)

Each feature flag is defined in a separate YAML file consisting of a number of fields:

| Field               | Required | Description                                                    |
|---------------------|----------|----------------------------------------------------------------|
| `name`              | yes      | Name of the feature flag.                                      |
| `type`              | yes      | Type of feature flag.                                          |
| `default_enabled`   | yes      | The default state of the feature flag.                         |
| `introduced_by_url` | yes      | The URL to the merge request that introduced the feature flag. |
| `milestone`         | yes      | Milestone in which the feature flag was created. |
| `group`             | yes      | The [group](https://handbook.gitlab.com/handbook/product/categories/#devops-stages) that owns the feature flag. |
| `feature_issue_url` | no       | The URL to the original feature issue.                         |
| `rollout_issue_url` | no       | The URL to the Issue covering the feature flag rollout.        |
| `log_state_changes` | no       | Used to log the state of the feature flag                      |

NOTE:
All validations are skipped when running in `RAILS_ENV=production`.

## Create a new feature flag

NOTE:
GitLab Pages uses [a different process](../pages/_index.md#feature-flags) for feature flags.

The GitLab codebase provides [`bin/feature-flag`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/bin/feature-flag),
a dedicated tool to create new feature flag definitions.
The tool asks various questions about the new feature flag, then creates
a YAML definition in `config/feature_flags` or `ee/config/feature_flags`.

Only feature flags that have a YAML definition file can be used when running the development or testing environments.

```shell
$ bin/feature-flag my_feature_flag
>> Specify the feature flag type
?> beta
You picked the type 'beta'

>> Specify the group label to which the feature flag belongs, from the following list:
1. group::group1
2. group::group2
?> 2
You picked the group 'group::group2'

>> URL of the original feature issue (enter to skip):
?> https://gitlab.com/gitlab-org/gitlab/-/issues/435435

>> URL of the MR introducing the feature flag (enter to skip and let Danger provide a suggestion directly in the MR):
?> https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141023

>> Username of the feature flag DRI (enter to skip):
?> bob

>> Is this an EE only feature (enter to skip):
?> [Return]

>> Press any key and paste the issue content that we copied to your clipboard! 🚀
?> [Return automatically opens the "New issue" page where you only have to paste the issue content]

>> URL of the rollout issue (enter to skip):
?> https://gitlab.com/gitlab-org/gitlab/-/issues/437162

create config/feature_flags/beta/my_feature_flag.yml
---
name: my_feature_flag
feature_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/435435
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141023
rollout_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/437162
milestone: '16.9'
group: group::composition analysis
type: beta
default_enabled: false
```

All newly-introduced feature flags must be [**disabled by default**](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/).

Features that are developed and merged behind a feature flag
should not include a changelog entry. The entry should be added either in the merge
request removing the feature flag or the merge request where the default value of
the feature flag is set to enabled. If the feature contains any database migrations, it
*should* include a changelog entry for the database changes.

NOTE:
To create a feature flag that is only used in EE, add the `--ee` flag: `bin/feature-flag --ee`

### Naming new flags

When choosing a name for a new feature flag, consider the following guidelines:

- A long, descriptive name is better than a short but confusing one.
- Write the name in snake case (`my_cool_feature_flag`).
- Avoid using `disable` in the name to avoid having to think (or [document](../documentation/feature_flags.md))
  with double negatives. Consider starting the name with `hide_`, `remove_`, or `disallow_`.

  In software engineering this problem is known as
  ["negative names for boolean variables"](https://www.serendipidata.com/posts/naming-guidelines-for-boolean-variables/).
  But we can't forbid negative words altogether, to be able to introduce flags as
  [disabled by default](#feature-flags-in-gitlab-development), use them to remove a feature by moving it behind a flag, or to [selectively disable a flag by actor](controls.md#selectively-disable-by-actor).

### Risk of a broken master (main) branch

WARNING:
Feature flags **must** be used in the MR that introduces them. Not doing so causes a
[broken master](https://handbook.gitlab.com/handbook/engineering/workflow/#broken-master) scenario due
to the `rspec:feature-flags` job that only runs on the `master` branch.

### Optionally add a `.patch` file for automated removal of feature flags

The [`gitlab-housekeeper`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper) is able to automatically remove your feature flag code for you using the [`DeleteOldFeatureFlags` keep](https://gitlab.com/gitlab-org/gitlab/-/blob/master/keeps/delete_old_feature_flags.rb). The tool will run periodically and automatically clean up old feature flags from the code.

For this tool to automatically remove the usages of the feature flag in your code you can add a `.patch` file alongside your feature flag YAML file. The file should be exactly the same name except using the `.patch` extension instead of the `.yml` extension.

For example you can create a patch file for `config/feature_flags/beta/my_feature_flag.yml` using the following steps:

1. Edit the code locally to remove the feature flag `my_feature_flag` usage assuming that the feature flag is already enabled and we are rolling forward
1. Run `git diff > config/feature_flags/beta/my_feature_flag.patch`
1. Undo the changes to the files where you removed the feature flag usage
1. Commit this file `config/feature_flags/beta/my_feature_flag.patch` file to the branch where you are adding the feature flag

Then in future the `gitlab-housekeeper` will automatically clean up your
feature flag for you by applying this patch.

## List all the feature flags

To [use ChatOps](../../ci/chatops/_index.md) to output all the feature flags in an environment to Slack, you can use the `run feature list`
command. For example:

```shell
/chatops run feature list --dev
/chatops run feature list --staging
```

## Toggle a feature flag

See [rolling out changes](controls.md#rolling-out-changes) for more information
about toggling feature flags.

## Delete a feature flag

See [cleaning up feature flags](controls.md#cleaning-up) for more information about
deleting feature flags.

## Migrate an `ops` feature flag to an application setting

To migrate an `ops` feature flag to an application setting:

1. In application settings, create or identify an existing `JSONB` column to store the setting.
1. Write a migration to backfill the column.
   For an example, see [merge request 148014](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148014).
1. Optional. In application settings, update the documentation for the setting.
1. In the **Admin** area, create a setting to enable or disable the feature.
1. Replace the feature flag everywhere with the application setting.
1. Update all the relevant documentation pages.
1. Mark the backfill migration as a `NOOP` and remove the feature flag after the mandatory upgrade path is crossed.
   For an example, see [merge request 151080](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151080).

The changes to backfill application settings and use the settings in the code must be merged in the same milestone.
If frontend changes are merged in a later milestone, you should add documentation about how to update the settings
by using the [application settings API](../../api/settings.md) or the Rails console.

## Develop with a feature flag

There are two main ways of using feature flags in the GitLab codebase:

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

Default behavior for not configured feature flags is controlled
by `default_enabled:` in YAML definition.

If feature flag does not have a YAML definition an error will be raised
in development or test environment, while returning `false` on production.

For feature flags that don't have a definition file (only allowed for the `experiment`, `worker` and `undefined` types),
you need to pass their `type:` when calling `Feature.enabled?` and `Feature.disabled?`:

```ruby
if Feature.enabled?(:experiment_feature_flag, project, type: :experiment)
  # execute code if feature flag is enabled
end

if Feature.disabled?(:worker_feature_flag, project, type: :worker)
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

#### Recursion detection

When there are many feature flags, it is not always obvious where they are
called. Avoid cycles where the evaluation of one feature flag requires the
evaluation of other feature flags. If this causes a cycle, it will be broken
and the default value will be returned.

To enable this recursion detection to work correctly, always access feature values through
`Feature::enabled?`, and avoid the low-level use of `Feature::get`. When this
happens, we track a `Feature::RecursionError` exception to the error tracker.

### Frontend

When using a feature flag for UI elements, make sure to _also_ use a feature
flag for the underlying backend code, if there is any. This ensures there is
absolutely no way to use the feature until it is enabled.

Use the `push_frontend_feature_flag` method which is available to all controllers that inherit from `ApplicationController`. You can use this method to expose the state of a feature flag, for example:

```ruby
before_action do
  # Prefer to scope it per project or user, for example
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

For feature flags that don't have a definition file (only allowed for the `experiment`, `worker` and `undefined` types),
you need to pass their `type:` when calling `push_frontend_feature_flag`:

```ruby
before_action do
  push_frontend_feature_flag(:vim_bindings, project, type: :experiment)
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

GitLab supports the following feature flag actors:

- `User` model
- `Project` model
- `Group` model
- Current request

The actor is a second parameter of the `Feature.enabled?` call. For example:

```ruby
Feature.enabled?(:feature_flag, project)
```

Models which `include FeatureGate` have an `.actor_from_id` class method.
If you have the model's ID and do not need the model for anything other than checking the feature
flag state, you can use `.actor_from_id` in order check the feature flag state without making a
database query to retrieve the model.

```ruby
# Bad -- Unnecessary query is executed
Feature.enabled?(:feature_flag, Project.find(project_id))

# Good -- No query for projects
Feature.enabled?(:feature_flag, Project.actor_from_id(project_id))

# Good -- Project model is used after feature flag check
project = Project.find(project_id)
return unless Feature.enabled?(:feature_flag, project)
project.update!(column: value)
```

See [Use ChatOps to enable and disable feature flags](controls.md#process) for details on how to use ChatOps
to selectively enable or disable feature flags in GitLab-provided environments, like staging and production.

Flag state is not inherited from a group by its subgroups or projects.
If you need a flag state to be consistent for an entire group hierarchy,
consider using the top-level group as the actor.
This group can be found by calling `#root_ancestor` on any group or project.

```ruby
Feature.enabled?(:feature_flag, group.root_ancestor)
```

#### Mixing actor types

Generally you should use only one type of actor in all invocations of `Feature.enabled?`
for a particular feature flag, and not mix different actor types.

Mixing actor types can lead to a feature being enabled or disabled inconsistently in ways
that can cause bugs. For example, if at the controller level a flag is checked using a
group actor and at the service level it is checked using a user actor, the feature may be
both enabled, and disabled at different points in the same request.

In some situations it is safe to mix actor types if you know that it won't lead to
inconsistent results. For example, a webhook can be associated with either a group or a
project, and so a feature flag for a webhook might leverage this to rollout a feature for
group and project webhooks using the same feature flag.

If you need to use different actor types and cannot safely mix them in your situation you
should use separate flags for each actor type instead. For example:

```ruby
Feature.enabled?(:feature_flag_group, group)
Feature.enabled?(:feature_flag_user, user)
```

#### Instance actor

WARNING:
Instance-wide feature flags should only be used when a feature is tied in to an entire instance. Always prioritize other actors first.

In some cases, you may want a feature flag to be enabled for an entire instance and not based on an actor. A great example are the Admin settings, where it would be impossible to enable the Feature Flag based on a group or a project since they are both `undefined`.

The user actor would cause confusion since a Feature Flag might be enabled for a user who is not an admin, but disabled for a user who is.

Instead, it is possible to use the `:instance` symbol as the second argument to `Feature.enabled?`, which will be sanitized as a GitLab instance.

```ruby
Feature.enabled?(:feature_flag, :instance)
```

#### Current request actor

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132078) in GitLab 16.5

It is not recommended to use percentage of time rollout, as each call may return
inconsistent results.

Rather it is advised to use the current request as an actor.

```ruby
# Bad
Feature.enable_percentage_of_time(:feature_flag, 40)
Feature.enabled?(:feature_flag)

# Good
Feature.enable_percentage_of_actors(:feature_flag, 40)
Feature.enabled?(:feature_flag, Feature.current_request)
```

When using the current request as the actor, the feature flag should return the
same value within the context of a request.
As the current request actor is implemented using [`SafeRequestStore`](../caching.md#low-level), we should
have consistent feature flag values within:

- a Rack request
- a Sidekiq worker execution
- an ActionCable worker execution

To migrate an existing feature from percentage of time to the current request
actor, it is recommended that you create a new feature flag.
This is because it is difficult to control the timing between existing
`percentage_of_time` values, the deployment of the code change, and switching to
use `percentage_of_actors`.

#### Use actors for verifying in production

WARNING:
Using production as a testing environment is not recommended. Use our testing
environments for testing features that are not production-ready.

While the staging environment provides a way to test features in an environment
that resembles production, it doesn't allow you to compare before-and-after
performance metrics specific to production environment. It can be useful to have a
project in production with your development feature flag enabled, to allow tools
like Sitespeed reports to reveal the metrics of the new code under a feature flag.

This approach is even more useful if you're already tracking the old codebase in
Sitespeed, enabling you to compare performance accurately before and after the
feature flag's rollout.

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

The available feature groups are:

| Group name            | Scoped to | Description |
| --------------------- | --------- | ----------- |
| `gitlab_team_members` | Users     | Enables the feature for users who are members of [`gitlab-com`](https://gitlab.com/gitlab-com) |

Feature groups can be enabled via the group name:

```ruby
Feature.enable(:feature_flag_name, :gitlab_team_members)
```

### Controlling feature flags locally

#### On rails console

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

When manually enabling or disabling a feature flag from the Rails console, its default value gets overwritten.
This can cause confusion when changing the flag's `default_enabled` attribute.

To reset the feature flag to the default status:

```ruby
Feature.remove(:feature_flag_name)
```

#### On your browser

Access `http://gdk.test:3000/rails/features` to see the manage locally the feature flag.

### Logging

Usage and state of the feature flag is logged if either:

- `log_state_changes` is set to `true` in the feature flag definition.
- `milestone` refers to a milestone that is greater than or equal to the current GitLab version.

When the state of a feature flag is logged, it can be identified by using the `"json.feature_flag_states": "feature_flag_name:1"` or `"json.feature_flag_states": "feature_flag_name:0"` condition in Kibana.
You can see an example in [this](https://log.gprd.gitlab.net/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:60000),time:(from:now-7d%2Fd,to:now))&_a=(columns:!(json.feature_flag_states),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,field:json.feature_flag_states,index:'7092c4e2-4eb5-46f2-8305-a7da2edad090',key:json.feature_flag_states,negate:!f,params:(query:'optimize_where_full_path_in:1'),type:phrase),query:(match_phrase:(json.feature_flag_states:'optimize_where_full_path_in:1')))),hideChart:!f,index:'7092c4e2-4eb5-46f2-8305-a7da2edad090',interval:auto,query:(language:kuery,query:''),sort:!(!(json.time,desc)))) link.

NOTE:
Only 20% of the requests log the state of the feature flags. This is controlled with the [`feature_flag_state_logs`](https://gitlab.com/gitlab-org/gitlab/-/blob/6deb6ecbc69f05a80d920a295dfc1a6a303fc7a0/config/feature_flags/ops/feature_flag_state_logs.yml) feature flag.

## Changelog

We want to avoid introducing a changelog when features are not accessible by an end-user either directly (example: ability to use the feature) or indirectly (examples: ability to take advantage of background jobs, performance improvements, or database migration updates).

- Database migrations are always accessible by an end-user indirectly, as self-managed customers need to be aware of database changes before upgrading. For this reason, they **should** have a changelog entry.
- Any change behind a feature flag **disabled** by default **should not** have a changelog entry.
- Any change behind a feature flag that is **enabled** by default **should** have a changelog entry.
- Changing the feature flag itself (flag removal, default-on setting) **should** have [a changelog entry](../changelog.md).
  Use the flowchart to determine the changelog entry type.

  ```mermaid
  flowchart LR
    FDOFF(Flag is currently<br>'default: off')
    FDON(Flag is currently<br>'default: on')
    CDO{Change to<br>'default: on'}
    ACF(added / changed / fixed / '...')
    RF{Remove flag}
    RF2{Remove flag}
    RC(removed / changed)
    OTHER(other)

    FDOFF -->CDO-->ACF
    FDOFF -->RF
    RF-->|Keep new code?| ACF
    RF-->|Keep old code?| OTHER

    FDON -->RF2
    RF2-->|Keep old code?| RC
    RF2-->|Keep new code?| OTHER
  ```

- The changelog for a feature flag should describe the feature and not the
  flag, unless a default on feature flag is removed keeping the new code (`other` in the flowchart above).
- A feature flag can also be used for rolling out a bug fix or a maintenance work. In this scenario, the changelog
  must be related to it, for example; `fixed` or `other`.

## Feature flags in tests

Introducing a feature flag into the codebase creates an additional code path that should be tested.
It is strongly advised to include automated tests for all code affected by a feature flag, both when **enabled** and **disabled**
to ensure the feature works properly. If automated tests are not included for both states, the functionality associated
with the untested code path should be manually tested before deployment to production.

When using the testing environment, all feature flags are enabled by default.
Flags can be disabled by default in the [`spec/spec_helper.rb` file](https://gitlab.com/gitlab-org/gitlab/-/blob/b61fba42eea2cf5bb1ca64e80c067a07ed5d1921/spec/spec_helper.rb#L274).
Add a comment inline to explain why the flag needs to be disabled. You can also attach the issue URL for reference if possible.

WARNING:
This does not apply to end-to-end (QA) tests, which [do not enable feature flags by default](#end-to-end-qa-tests). There is a different [process for using feature flags in end-to-end tests](../testing_guide/end_to_end/best_practices/feature_flags.md).

To disable a feature flag in a test, use the `stub_feature_flags`
helper. For example, to globally disable the `ci_live_trace` feature
flag in a test:

```ruby
stub_feature_flags(ci_live_trace: false)

Feature.enabled?(:ci_live_trace) # => false
```

A common pattern of testing both paths looks like:

```ruby
it 'ci_live_trace works' do
  # tests assuming ci_live_trace is enabled in tests by default
  Feature.enabled?(:ci_live_trace) # => true
end

context 'when ci_live_trace is disabled' do
  before do
    stub_feature_flags(ci_live_trace: false)
  end

  it 'ci_live_trace does not work' do
    Feature.enabled?(:ci_live_trace) # => false
  end
end
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

### Controlling feature flags engine in tests

Our Flipper engine in the test environment works in a memory mode `Flipper::Adapters::Memory`.
`production` and `development` modes use `Flipper::Adapters::ActiveRecord`.

You can control whether the `Flipper::Adapters::Memory` or `ActiveRecord` mode is being used.

#### `stub_feature_flags: true` (default and preferred)

In this mode Flipper is configured to use `Flipper::Adapters::Memory` and mark all feature
flags to be on-by-default and persisted on a first use.

Make sure behavior under feature flag doesn't go untested in some non-specific contexts.

### `stub_feature_flags: false`

This disables a memory-stubbed flipper, and uses `Flipper::Adapters::ActiveRecord`
a mode that is used by `production` and `development`.

You should use this mode only when you really want to tests aspects of Flipper
with how it interacts with `ActiveRecord`.

### End-to-end (QA) tests

Toggling feature flags works differently in end-to-end (QA) tests. The end-to-end test framework does not have direct access to
Rails or the database, so it can't use Flipper. Instead, it uses [the public API](../../api/features.md#set-or-create-a-feature). Each end-to-end test can [enable or disable a feature flag during the test](../testing_guide/end_to_end/best_practices/feature_flags.md). Alternatively, you can enable or disable a feature flag before one or more tests when you [run them from your GitLab repository's `qa` directory](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa#running-tests-with-a-feature-flag-enabled-or-disabled), or if you [run the tests via GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#running-tests-with-a-feature-flag-enabled).

[As noted above, feature flags are not enabled by default in end-to-end tests.](#feature-flags-in-tests)
This means that end-to-end tests will run with feature flags in the default state implemented in the source
code, or with the feature flag in its current state on the GitLab instance under test, unless the
test is written to enable/disable a feature flag explicitly.

When a feature flag is changed on Staging or on GitLab.com, a Slack message will be posted to the `#e2e-run-staging` or `#e2e-run-production` channels to inform
the pipeline triage DRI so that they can more easily determine if any failures are related to a feature flag change. However, if you are working on a change you can
help to avoid unexpected failures by [confirming that the end-to-end tests pass with a feature flag enabled.](../testing_guide/end_to_end/best_practices/feature_flags.md#confirming-that-end-to-end-tests-pass-with-a-feature-flag-enabled)

## Controlling Sidekiq worker behavior with feature flags

Feature flags with [`worker` type](#worker-type) can be used to control the behavior of a Sidekiq worker.

### Deferring Sidekiq jobs

When disabled, feature flags with the format of `run_sidekiq_jobs_{WorkerName}` delay the execution of the worker
by scheduling the job at a later time. This feature flag is enabled by default for all workers.
Deferring jobs can be useful during an incident where contentious behavior from
worker instances are saturating infrastructure resources (such as database and database connection pool).
The implementation can be found at [SkipJobs Sidekiq server middleware](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/sidekiq_middleware/skip_jobs.rb).

NOTE:
Jobs are deferred indefinitely as long as the feature flag is disabled. It is important to remove the
feature flag after the worker is deemed safe to continue processing.

When set to false, 100% of the jobs are deferred. When you want processing to resume, you can
use a **percentage of time** rollout. For example:

```shell
# not running any jobs, deferring all 100% of the jobs
/chatops run feature set run_sidekiq_jobs_SlowRunningWorker false

# only running 10% of the jobs, deferring 90% of the jobs
/chatops run feature set run_sidekiq_jobs_SlowRunningWorker 10

# running 50% of the jobs, deferring 50% of the jobs
/chatops run feature set run_sidekiq_jobs_SlowRunningWorker 50

# back to running all jobs normally
/chatops run feature delete run_sidekiq_jobs_SlowRunningWorker
```

### Dropping Sidekiq jobs

Instead of [deferring jobs](#deferring-sidekiq-jobs), jobs can be entirely dropped by enabling the feature flag
`drop_sidekiq_jobs_{WorkerName}`. Use this feature flag when you are certain the jobs do not need to be processed in the future, and therefore are safe to be dropped.

```shell
# drop all the jobs
/chatops run feature set drop_sidekiq_jobs_SlowRunningWorker true

# process jobs normally
/chatops run feature delete drop_sidekiq_jobs_SlowRunningWorker
```

NOTE:
Dropping feature flag (`drop_sidekiq_jobs_{WorkerName}`) takes precedence over deferring feature flag (`run_sidekiq_jobs_{WorkerName}`). When `drop_sidekiq_jobs` is enabled and `run_sidekiq_jobs` is disabled, jobs are entirely dropped.
