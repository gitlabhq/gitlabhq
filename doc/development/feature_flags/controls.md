---
stage: none
group: unassigned
info: "See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
title: Use ChatOps to enable and disable feature flags
---

NOTE:
This document explains how to contribute to the development of the GitLab product.
If you want to use feature flags to show and hide functionality in your own applications,
view [this feature flags information](../../operations/feature_flags.md) instead.

To turn on/off features behind feature flags in any of the
GitLab-provided environments, like staging and production, you need to
have access to the [ChatOps](../chatops_on_gitlabcom.md) bot. The ChatOps bot
is currently running on the ops instance, which is different from
[GitLab.com](https://gitlab.com) or `dev.gitlab.org`.

Follow the ChatOps document to [request access](../chatops_on_gitlabcom.md#requesting-access).

After you are added to the project test if your access propagated,
run:

```shell
/chatops run feature --help
```

## Rolling out changes

When the changes are deployed to the environments it is time to start
rolling out the feature to our users. The exact procedure of rolling out a
change is unspecified, as this can vary from change to change. However, in
general we recommend rolling out changes incrementally, instead of enabling them
for everybody right away. We also recommend you to _not_ enable a feature
_before_ the code is being deployed.
This allows you to separate rolling out a feature from a deploy, making it
easier to measure the impact of both separately.

The GitLab feature library (using
[Flipper](https://github.com/jnunemaker/flipper), and covered in the
[Feature flags process](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/) guide) supports rolling out changes to a percentage of
time to users. This in turn can be controlled using [GitLab ChatOps](../../ci/chatops/_index.md).

For an up to date list of feature flag commands see
[the source code](https://gitlab.com/gitlab-com/chatops/blob/master/lib/chatops/commands/feature.rb).
All the examples in that file must be preceded by `/chatops run`.

If you get an error "Whoops! This action is not allowed. This incident
will be reported." that means your Slack account is not allowed to
change feature flags or you do not have access.

### Enabling a feature for pre-production testing

As a first step in a feature rollout, you should enable the feature on
`staging.gitlab.com`
and `dev.gitlab.org`.

These two environments have different scopes.
`dev.gitlab.org` is a production CE environment that has internal GitLab Inc.
traffic and is used for some development and other related work.
`staging.gitlab.com` has a smaller subset of GitLab.com database and repositories
and does not have regular traffic. Staging is an EE instance and can give you
a (very) rough estimate of how your feature will look and behave on GitLab.com.
Both of these instances are connected to Sentry so make sure you check the projects
there for any exceptions while testing your feature after enabling the feature flag.

For these pre-production environments, it's strongly encouraged to run the command in
`#staging`, `#production`, or `#chatops-ops-test`, for improved visibility.

#### Enabling the feature flag for a given percentage of actors

To enable a feature 25% of the time for any given actor, run the following in Slack:

```shell
/chatops run feature set new_navigation_bar 25 --actors --dev
/chatops run feature set new_navigation_bar 25 --actors --staging
```

See [percentage of actors](#percentage-based-actor-selection) for your choices of actors
for which you would like to randomize the rollout.

### Enabling a feature for GitLab.com

When a feature has successfully been
[enabled on a pre-production](#enabling-a-feature-for-pre-production-testing)
environment and verified as safe and working, you can roll out the
change to GitLab.com (production).

If a feature is [deprecated](../../update/deprecations.md), do not enable the flag.

#### Communicate the change

Some feature flag changes on GitLab.com should be communicated with
parts of the company. The developer responsible needs to determine
whether this is necessary and the appropriate level of communication.
This depends on the feature and what sort of impact it might have.

Guidelines:

- Notify `#support_gitlab-com` beforehand. So in case if the feature has any side effects on user experience, they can mitigate and disable the feature flag to reduce some impact.
- If the feature meets the requirements for creating a [Change Management](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/#feature-flags-and-the-change-management-process) issue, create a Change Management issue per [criticality guidelines](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/#change-request-workflows).
- For simple, low-risk, easily reverted features, proceed and [enable the feature in `#production`](#process).
- For support requests to toggle feature flags for specific groups or projects, follow the process outlined in the [support workflows](https://handbook.gitlab.com/handbook/support/workflows/saas_feature_flags/).

#### Guideline for which percentages to choose during the rollout

Choosing which the percentages while rolling out the feature flag
depends on different factors, for example:

- Is the feature flag checked often so that you can collect enough information to decide it's safe to continue with the rollout?
- If something goes wrong with the feature, how many requests or customers will be impacted?
- If something goes wrong, are there any other GitLab publicly available features that will be impacted by the rollout?
- Are there any possible performance degradation from rolling out the feature flag?

Let's take some examples for different types of feature flags, and how you can consider the rollout
in these cases:

##### A. Feature flag for an operation that runs a few times per day

Let's say you are releasing a new functionality that runs a few times per day, for example, in a daily or
hourly cron job. And this new functionality is controlled by the newly introduced feature flag.
For example, [rewriting the database query for a cron job](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128759/diffs).
In this case, releasing the feature flag for a percentage below 25% might give you slow feedback
regarding whether to proceed with the rollout or not. Also, if the cron job fails, it will [retry](../sidekiq/_index.md#retries).
So the consequences of something going wrong won't be that big. In this case, releasing with a percentage of 25% or 50%
will be an acceptable choice.

But you have to make sure to log the result of the feature flag check to the log of your worker. See instructions
[here](../logging.md#logging-context-metadata-through-rails-or-grape-requests)
about best practices for logging.

##### B. Feature flag for an operation that runs hundreds or thousands times per day

Your newly introduced feature or change might be more customer facing than whatever runs in Sidekiq jobs. But
it might not be run often. In this case, choose a percentage high enough to collect some results in order
to know whether to proceed or not. You can consider starting with `5%` or `10%` in this case, while monitoring
the logs for any errors, or returned `500`s statuses to the users.

But as you continue with the rollout and increasing the percentage, you will need to consider looking at the
performance impact of the feature. You can consider monitoring
the [Latency: Apdex and error ratios](https://dashboards.gitlab.net/d/general-triage/general-platform-triage?orgId=1)
dashboard on Grafana.

##### C. Feature flag for an operation that runs at the core of the app

Sometimes, a new change that might touch every aspect of the GitLab application. For example, changing
a database query on one of the core models, like `User`, `Project` or `Namespace`. In this case, releasing
the feature for `1%` of the requests, or even less than that (via Change Request) is highly recommended to avoid any incidents.
See [this change request example](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16427) of a feature flag that was released
for around `0.1%` of the requests, due to the high impact of the change.

To make sure that the rollout does not affect many customers, consider following these steps:

1. Estimate how many requests per minute can be affected by 100% of the feature flag rollout. This
   can be achieved by tracking
   the database queries. See [the instructions here](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/mapping_statements.md#example-queries).
1. Calculate the reasonable number of requests or users that can be affected, in case
   the rollout doesn't go as expected.
1. Based on the numbers collected from (1) and (2), calculate the reasonable percentage to start with to roll out
   the feature flag. Here is [an example](https://gitlab.com/gitlab-org/gitlab/-/issues/425859#note_1576923174)
   of such calculation.
1. Make sure to communicate your findings on the rollout issue of the feature flag.

##### D. Unknown impact of releasing the feature flag

If you are not certain what percentages to use, then choose the safe recommended option, and choose these percentages:

1. 1%
1. 10%
1. 25%
1. 50%
1. 75%
1. 100%

Between every step you'll want to wait a little while and monitor the
appropriate graphs on <https://dashboards.gitlab.net>. The exact time to wait
may differ. For some features a few minutes is enough, while for others you may
want to wait several hours or even days. This is entirely up to you, just make
sure it is clearly communicated to your team and the Production team if you
anticipate any potential problems.

#### Process

When enabling a feature flag rollout, the system will automatically block the
ChatOps command from succeeding if there are active `"severity::1"` or `~"severity::2"`
incidents or in-progress change issues, for example:

```shell
/chatops run feature set gitaly_lfs_pointers_pipeline true

- Production checks fail!
- active incidents

  2021-06-29 Canary deployment failing QA tests
```

Before enabling a feature flag, verify that you are not violating any [Production Change Lock periods](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/#production-change-lock-pcl) and are in compliance with the [Feature flags and the Change Management Process](https://handbook.gitlab.com/handbook/engineering/infrastructure/change-management/#feature-flags-and-the-change-management-process).

The following `/chatops` commands must be performed in the Slack
`#production` channel.

##### Percentage of actors roll out

To enable a feature for 25% of actors such as users, projects, groups or the current request or job,
run the following in Slack:

```shell
/chatops run feature set some_feature 25 --actors
```

This sets a feature flag to `true` based on the following formula:

```ruby
feature_flag_state = Zlib.crc32("some_feature<Actor>:#{actor.id}") % (100 * 1_000) < 25 * 1_000
# where <Actor>: is a `User`, `Group`, `Project` and actor is an instance
```

During development, based on the nature of the feature, an actor choice
should be made.

For user focused features:

```ruby
Feature.enabled?(:feature_cool_avatars, current_user)
```

For group or namespace level features:

```ruby
Feature.enabled?(:feature_cooler_groups, group)
```

For project level features:

```ruby
Feature.enabled?(:feature_ice_cold_projects, project)
```

For current request:

```ruby
Feature.enabled?(:feature_ice_cold_projects, Feature.current_request)
```

Feature gates can also be actor based, for example a feature could first be
enabled for only the `gitlab` project. The project is passed by supplying a
`--project` flag:

```shell
/chatops run feature set --project=gitlab-org/gitlab some_feature true
```

You can use the `--user` option to enable a feature flag for a specific user:

```shell
/chatops run feature set --user=myusername some_feature true
```

If you would like to gather feedback internally first,
feature flags scoped to a user can also be enabled
for GitLab team members with the `gitlab_team_members`
[feature group](_index.md#feature-groups):

```shell
/chatops run feature set --feature-group=gitlab_team_members some_feature true
```

You can use the `--group` flag to enable a feature flag for a specific group:

```shell
/chatops run feature set --group=gitlab-org some_feature true
```

Note that `--group` does not work with user namespaces. To enable a feature flag for a
generic namespace (including groups) use `--namespace`:

```shell
/chatops run feature set --namespace=gitlab-org some_feature true
/chatops run feature set --namespace=myusername some_feature true
```

Actor-based gates are applied before percentages. For example, considering the
`group/project` as `gitlab-org/gitlab` and a given example feature as `some_feature`, if
you run these 2 commands:

```shell
/chatops run feature set --project=gitlab-org/gitlab some_feature true
/chatops run feature set some_feature 25 --actors
```

Then `some_feature` will be enabled for both 25% of actors and always when interacting with
`gitlab-org/gitlab`. This is a good idea if the feature flag development makes use of group
actors.

```ruby
Feature.enabled?(:some_feature, group)
```

Multiple actors can be passed together in a comma-separated form:

```shell
/chatops run feature set --project=gitlab-org/gitlab,example-org/example-project some_feature true

/chatops run feature set --group=gitlab-org,example-org some_feature true

/chatops run feature set --namespace=gitlab-org,example-org some_feature true
```

Lastly, to verify that the feature is deemed stable in as many cases as possible,
you should fully roll out the feature by enabling the flag **globally** by running:

```shell
/chatops run feature set some_feature true
```

This changes the feature flag state to be **enabled** always, which overrides the
existing gates (for example, `--group=gitlab-org`) in the above processes.

Note, that if an actor based feature gate is present, switching the
`default_enabled` attribute of the YAML definition from `false` to `true`
will not have any effect. The feature gate must be deleted first.

For example, a feature flag is set via ChatOps:

```shell
/chatops run feature set --project=gitlab-org/gitlab some_feature true
```

When the `default_enabled` attribute in the YAML definition is switched to
`true`, the feature gate must be deleted to have the desired effect:

```shell
/chatops run feature delete some_feature
```

##### Percentage of time roll out (deprecated)

Previously, to enable a feature 25% of the time, we would run the following in Slack:

```shell
/chatops run feature set new_navigation_bar 25 --random
```

This command enables the `new_navigation_bar` feature for GitLab.com. However, this command does *not* enable the feature for 25% of the total users.
Instead, when the feature is checked with `enabled?`, it returns `true` 25% of the time.

Percentage of time feature flags are now deprecated in favor of [percentage of actors](#percentage-based-actor-selection)
using the `Feature.current_request` actor. The problem with not using an actor is that the randomized
choice evaluates for each call into `Feature.enabled?` rather than once per request or job execution,
which can lead to flip-flopping between states. For example:

```ruby
feature_flag_state = rand < (25 / 100.0)
```

For the time being, we continue to allow use of percentage of time feature flags.
During rollout, you can force it using the `--ignore-random-deprecation-check` switch in ChatOps.

##### Disabling feature flags

To disable a feature flag that has been globally enabled you can run:

```shell
/chatops run feature set some_feature false
```

To disable a feature flag that has been enabled for a specific project you can run:

```shell
/chatops run feature set --project=gitlab-org/gitlab some_feature false
```

You cannot selectively disable feature flags for a specific project/group/user without applying a [specific method of implementing](controls.md#selectively-disable-by-actor) the feature flags.

If a feature flag is disabled via ChatOps, that will take precedence over the `default_enabled` value in the YAML. In other words, you could have a feature enabled for on-premise installations but not for GitLab.com.

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

#### Percentage-based actor selection

When using the percentage rollout of actors on multiple feature flags, the actors for each feature flag are selected separately.

For example, the following feature flags are enabled for a certain percentage of actors:

```plaintext
/chatops run feature set feature-set-1 25 --actors
/chatops run feature set feature-set-2 25 --actors
```

If a project A has `:feature-set-1` enabled, there is no guarantee that project A also has `:feature-set-2` enabled.

For more detail, see [This is how percentages work in Flipper](https://www.hackwithpassion.com/this-is-how-percentages-work-in-flipper/).

### Verifying metrics after enabling feature flag

After turning on the feature flag, you need to [monitor the relevant graphs](https://handbook.gitlab.com/handbook/engineering/monitoring/) between each step:

1. Go to [`dashboards.gitlab.net`](https://dashboards.gitlab.net).
1. Turn on the `feature-flag`.
1. Watch `Latency: Apdex` for services that might be impacted by your change
   (like `sidekiq service`, `api service` or `web service`). Then check out more in-depth
   dashboards by selecting `Service Overview Dashboards` and choosing a dashboard that might
   be related to your change.

In this illustration, you can see that the Apdex score started to decline after the feature flag was enabled at `09:46`. The feature flag was then deactivated at `10:31`, and the service returned to the original value:

![Feature flag metrics](../img/feature-flag-metrics_v15_8.png)

Certain features necessitate extensive monitoring over multiple days, particularly those that are high-risk and critical to business operations. In contrast, other features may only require a 24-hour monitoring period before continuing with the rollout.

It is recommended to determine the necessary extent of monitoring before initiating the rollout.

### Feature flag change logging

#### ChatOps level

Any feature flag change that affects GitLab.com (production) via [ChatOps](https://gitlab.com/gitlab-com/chatops)
is automatically logged in an issue.

The issue is created in the
[gl-infra/feature-flag-log](https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues?scope=all&state=closed)
project, and it will at minimum log the Slack handle of person enabling
a feature flag, the time, and the name of the flag being changed.

The issue is then also posted to the GitLab internal
[Grafana dashboard](https://dashboards.gitlab.net/) as an annotation
marker to make the change even more visible.

Changes to the issue format can be submitted in the
[ChatOps project](https://gitlab.com/gitlab-com/chatops).

#### Instance level

Any feature flag change that affects any GitLab instance is automatically logged in
[features_json.log](../../administration/logs/_index.md#features_jsonlog).
You can search the change history in [Kibana](https://handbook.gitlab.com/handbook/support/workflows/kibana/).
You can also access the feature flag change history for GitLab.com [in Kibana](https://log.gprd.gitlab.net/goto/d060337c017723084c6d97e09e591fc6).

## Cleaning up

A feature flag should be removed as soon as it is no longer needed. Each additional
feature flag in the codebase increases the complexity of the application
and reduces confidence in our testing suite covering all possible combinations.
Additionally, a feature flag overwritten in some of the environments can result
in undefined and untested system behavior.

`development` type feature flags should have a short lifecycle because their purpose
is for rolling out a persistent change. `development` feature flags that are older
than 2 milestones are reported to engineering managers. The
[report tool](https://gitlab.com/gitlab-org/gitlab-feature-flag-alert) runs on a
monthly basis. For example, see [the report for December 2021](https://gitlab.com/gitlab-org/quality/triage-reports/-/issues/5480).

If a `development` feature flag is still present in the codebase after 6 months we should
take one of the following actions:

- Enable the feature flag by default and remove it.
- Convert it to an instance, group, or project setting.
- Revert the changes if it's still disabled and not needed anymore.

To remove a feature flag, open **one merge request** to make the changes. In the MR:

1. Add the ~"feature flag" label so release managers are aware of the removal.
1. If the merge request has to be backported into the current version, follow the
   [patch release runbook](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md) process.
   See [the feature flag process](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#including-a-feature-behind-feature-flag-in-the-final-release)
   for further details.
1. Remove all references to the feature flag from the codebase, including tests.
1. Remove the YAML definition for the feature from the repository.

Once the above MR has been merged, you should:

1. [Clean up the feature flag from all environments](#cleanup-chatops) with `/chatops run feature delete some_feature`.
1. Close the rollout issue for the feature flag after the feature flag is removed from the codebase.

### Cleanup ChatOps

When a feature gate has been removed from the codebase, the feature
record still exists in the database that the flag was deployed too.
The record can be deleted once the MR is deployed to all the environments:

```shell
/chatops run feature delete <feature-flag-name> --dev --pre --staging --staging-ref --production
```
