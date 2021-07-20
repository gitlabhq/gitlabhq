---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Feature flag controls

## Access

To be able to turn on/off features behind feature flags in any of the
GitLab Inc. provided environments such as staging and production, you need to
have access to the [ChatOps](../chatops_on_gitlabcom.md) bot. The ChatOps bot
is currently running on the ops instance, which is different from <https://gitlab.com> or <https://dev.gitlab.org>.

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
[Flipper](https://github.com/jnunemaker/flipper), and covered in the [Feature
Flags process](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/) guide) supports rolling out changes to a percentage of
time to users. This in turn can be controlled using [GitLab ChatOps](../../ci/chatops/index.md).

For an up to date list of feature flag commands please see [the source
code](https://gitlab.com/gitlab-com/chatops/blob/master/lib/chatops/commands/feature.rb).
Note that all the examples in that file must be preceded by
`/chatops run`.

If you get an error "Whoops! This action is not allowed. This incident
will be reported." that means your Slack account is not allowed to
change feature flags or you do not [have access](#access).

### Enabling a feature for pre-production testing

As a first step in a feature rollout, you should enable the feature on <https://about.staging.gitlab.com>
and <https://dev.gitlab.org>.

These two environments have different scopes.
`dev.gitlab.org` is a production CE environment that has internal GitLab Inc.
traffic and is used for some development and other related work.
`staging.gitlab.com` has a smaller subset of GitLab.com database and repositories
and does not have regular traffic. Staging is an EE instance and can give you
a (very) rough estimate of how your feature will look/behave on GitLab.com.
Both of these instances are connected to Sentry so make sure you check the projects
there for any exceptions while testing your feature after enabling the feature flag.

For these pre-production environments, the commands should be run in a
Slack channel for the stage the feature is relevant to. For example, use the
`#s_monitor` channel for features developed by the Monitor stage, Health
group.

To enable a feature for 25% of all users, run the following in Slack:

```shell
/chatops run feature set new_navigation_bar 25 --dev
/chatops run feature set new_navigation_bar 25 --staging
```

### Enabling a feature for GitLab.com

When a feature has successfully been
[enabled on a pre-production](#enabling-a-feature-for-pre-production-testing)
environment and verified as safe and working, you can roll out the
change to GitLab.com (production).

#### Communicate the change

Some feature flag changes on GitLab.com should be communicated with
parts of the company. The developer responsible needs to determine
whether this is necessary and the appropriate level of communication.
This depends on the feature and what sort of impact it might have.

Guidelines:

1. If the feature meets the requirements for creating a [Change Management](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/#feature-flags-and-the-change-management-process) issue, create a Change Management issue per [criticality guidelines](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/#change-request-workflows).
1. For simple, low-risk, easily reverted features, proceed and [enable the feature in `#production`](#process).
1. For features that impact the user experience, consider notifying `#support_gitlab-com` beforehand.

#### Process

Before toggling any feature flag, check that there are no ongoing
significant incidents on GitLab.com. You can do this by checking the
`#production` and `#incident-management` Slack channels, or looking for
[open incident issues](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?scope=all&state=opened&label_name[]=incident)
(although check the dates and times).

We do not want to introduce changes during an incident, as it can make
diagnosis and resolution of the incident much harder to achieve, and
also will largely invalidate your rollout process as you will be unable
to assess whether the rollout was without problems or not.

If there is any doubt, ask in `#production`.

The following `/chatops` commands should be performed in the Slack
`#production` channel.

When you begin to enable the feature, please link to the relevant
Feature Flag Rollout Issue within a Slack thread of the first `/chatops`
command you make so people can understand the change if they need to.

To enable a feature for 25% of the time, run the following in Slack:

```shell
/chatops run feature set new_navigation_bar 25
```

This sets a feature flag to `true` based on the following formula:

```ruby
feature_flag_state = rand < (25 / 100.0)
```

This will enable the feature for GitLab.com, with `new_navigation_bar` being the
name of the feature.
This command does *not* enable the feature for 25% of the total users.
Instead, when the feature is checked with `enabled?`, it will return `true` 25% of the time.

To enable a feature for 25% of actors such as users, projects, or groups,
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

If you are not certain what percentages to use, simply use the following steps:

1. 25%
1. 50%
1. 75%
1. 100%

Between every step you'll want to wait a little while and monitor the
appropriate graphs on <https://dashboards.gitlab.net>. The exact time to wait
may differ. For some features a few minutes is enough, while for others you may
want to wait several hours or even days. This is entirely up to you, just make
sure it is clearly communicated to your team, and the Production team if you
anticipate any potential problems.

Feature gates can also be actor based, for example a feature could first be
enabled for only the `gitlab` project. The project is passed by supplying a
`--project` flag:

```shell
/chatops run feature set --project=gitlab-org/gitlab some_feature true
```

For groups the `--group` flag is available:

```shell
/chatops run feature set --group=gitlab-org some_feature true
```

Note that actor-based gates are applied before percentages. For example, considering the
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

For example, a feature flag is set via chatops:

```shell
/chatops run feature set --project=gitlab-org/gitlab some_feature true
```

When the `default_enabled` attribute in the YAML definition is switched to
`true`, the feature gate must be deleted to have the desired effect:

```shell
/chatops run feature delete some_feature
```

##### Percentage of actors vs percentage of time rollouts

If you want to make sure a feature is always on or off for users, use a **Percentage of actors**
rollout. Avoid using percentage of _time_ rollouts in this case.

A percentage of _time_ rollout can introduce inconsistent behavior when `Feature.enabled?`
is used multiple times in the code because the feature flag value is randomized each time
`Feature.enabled?` is called on your code path.

##### Disabling feature flags

To disable a feature flag that has been globally enabled you can run:

```shell
/chatops run feature set some_feature false
```

To disable a feature flag that has been enabled for a specific project you can run:

```shell
/chatops run feature set --group=gitlab-org some_feature false
```

You cannot selectively disable feature flags for a specific project/group/user without applying a [specific method of implementing](index.md#selectively-disable-by-actor) the feature flags.

If a feature flag is disabled via chatops, that will take precedence over the `default_enabled` value in the YML. In other words, you could have a feature enabled for on-premise installations but not for GitLab.com.

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
[features_json.log](../../administration/logs.md#features_jsonlog).
You can search the change history in [Kibana](https://about.gitlab.com/handbook/support/workflows/kibana.html).
You can also access the feature flag change history for GitLab.com [in Kibana](https://log.gprd.gitlab.net/goto/d060337c017723084c6d97e09e591fc6).

## Cleaning up

A feature flag should be removed as soon as it is no longer needed. Each additional
feature flag in the codebase increases the complexity of the application
and reduces confidence in our testing suite covering all possible combinations.
Additionally, a feature flag overwritten in some of the environments can result
in undefined and untested system behavior.

To remove a feature flag, open **one merge request** to make the changes. In the MR:

1. Add the ~"feature flag" label so release managers are aware the changes are hidden behind a feature flag.
1. If the merge request has to be picked into a stable branch, add the
   appropriate `~"Pick into X.Y"` label, for example `~"Pick into 13.0"`.
   See [the feature flag process](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#including-a-feature-behind-feature-flag-in-the-final-release)
   for further details.
1. Remove all references to the feature flag from the codebase, including tests.
1. Remove the YAML definition for the feature from the repository.

Once the above MR has been merged, you should:

1. [Clean up the feature flag from all environments](#cleanup-chatops) with `/chatops run feature delete some_feature`.
1. Close the rollout issue for the feature flag after the feature flag is removed from the codebase.

### Cleanup ChatOps

When a feature gate has been removed from the codebase, the feature
record still exists in the database that the flag was deployed too.
The record can be deleted once the MR is deployed to each environment:

```shell
/chatops run feature delete some_feature --dev
/chatops run feature delete some_feature --staging
```

Then, you can delete it from production after the MR is deployed to prod:

```shell
/chatops run feature delete some_feature
```
