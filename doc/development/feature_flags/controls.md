# Feature flag controls

## Access

To be able to turn on/off features behind feature flags in any of the
GitLab Inc. provided environments such as staging and production, you need to
have access to the [Chatops](../chatops_on_gitlabcom.md) bot. The Chatops bot
is currently running on the ops instance, which is different from <https://gitlab.com> or <https://dev.gitlab.org>.

Follow the Chatops document to [request access](../chatops_on_gitlabcom.md#requesting-access).

Once you are added to the project test if your access propagated,
run:

```
/chatops run feature --help
```

## Where to run commands

To increase visibility, we recommend that GitLab team members run feature flag
related Chatops commands within certain Slack channels based on the environment
and related feature. For the [staging](https://staging.gitlab.com)
and [development](https://dev.gitlab.org) environments of GitLab.com,
the commands should run in a channel for the stage the feature is relevant too.

For example, use the `#s_monitor` channel for features developed by the
Monitor stage, Health group.

For all production environment Chatops commands, use the `#production` channel.

Regardless of the channel in which the Chatops command is ran, any feature flag change that affects GitLab.com will automatically be logged in an issue.

The issue is created in the [gl-infra/feature-flag-log](https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/issues?scope=all&utf8=%E2%9C%93&state=closed) project, and it will at minimum log the Slack handle of person enabling a feature flag, the time, and the name of the flag being changed.

The issue is then also posted to GitLab Inc. internal [Grafana dashboard](https://dashboards.gitlab.net/) as an annotation marker to make the change even more visible.

Changes to the issue format can be submitted in the [Chatops project](https://gitlab.com/gitlab-com/chatops).

## Rolling out changes

When the changes are deployed to the environments it is time to start
rolling out the feature to our users. The exact procedure of rolling out a
change is unspecified, as this can vary from change to change. However, in
general we recommend rolling out changes incrementally, instead of enabling them
for everybody right away. We also recommend you to _not_ enable a feature
_before_ the code is being deployed.
This allows you to separate rolling out a feature from a deploy, making it
easier to measure the impact of both separately.

GitLab's feature library (using
[Flipper](https://github.com/jnunemaker/flipper), and covered in the [Feature
Flags process](process.md) guide) supports rolling out changes to a percentage of
users. This in turn can be controlled using [GitLab Chatops](../../ci/chatops/README.md).

For an up to date list of feature flag commands please see [the source
code](https://gitlab.com/gitlab-com/chatops/blob/master/lib/chatops/commands/feature.rb).
Note that all the examples in that file must be preceded by
`/chatops run`.

If you get an error "Whoops! This action is not allowed. This incident
will be reported." that means your Slack account is not allowed to
change feature flags or you do not [have access](#access).

### Enabling feature for preproduction testing

As a first step in a feature rollout, you should enable the feature on <https://staging.gitlab.com>
and <https://dev.gitlab.org>.

For example, to enable a feature for 25% of all users, run the following in
Slack:

```
/chatops run feature set new_navigation_bar 25 --dev
/chatops run feature set new_navigation_bar 25 --staging
```

These two environments have different scopes.
`dev.gitlab.org` is a production CE environment that has internal GitLab Inc.
traffic and is used for some development and other related work.
`staging.gitlab.com` has a smaller subset of GitLab.com database and repositories
and does not have regular traffic. Staging is an EE instance and can give you
a (very) rough estimate of how your feature will look/behave on GitLab.com.
Both of these instances are connected to Sentry so make sure you check the projects
there for any exceptions while testing your feature after enabling the feature flag.

Once you are confident enough that these environments are in a good state with your
feature enabled, you can roll out the change to GitLab.com.

### Enabling a feature for GitLab.com

Similar to above, to enable a feature for 25% of all users, run the following in
Slack:

```
/chatops run feature set new_navigation_bar 25
```

This will enable the feature for GitLab.com, with `new_navigation_bar` being the
name of the feature.

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

```
/chatops run feature set --project=gitlab-org/gitlab some_feature true
```

For groups the `--group` flag is available:

```
/chatops run feature set --group=gitlab-org some_feature true
```

## Cleaning up

Once the change is deemed stable, submit a new merge request to remove the
feature flag. This ensures the change is available to all users and self-hosted
instances. Make sure to add the ~"feature flag" label to this merge request so
release managers are aware the changes are hidden behind a feature flag. If the
merge request has to be picked into a stable branch, make sure to also add the
appropriate "Pick into X" label (e.g. "Pick into XX.X").
See [the process document](process.md#including-a-feature-behind-feature-flag-in-the-final-release) for further details.

When a feature gate has been removed from the code base, the feature
record still exists in the database that the flag was deployed too.
The record can be deleted once the MR is deployed to each environment:

```sh
/chatops run feature delete some_feature --dev
/chatops run feature delete some_feature --staging
```

Then, you can delete it from production after the MR is deployed to prod:

```sh
/chatops run feature delete some_feature
```
