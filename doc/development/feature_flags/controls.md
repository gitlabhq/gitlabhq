# Access for enabling a feature flag in production

In order to be able to turn on/off features behind feature flags in any of the
GitLab Inc. provided environments such as staging and production, you need to
have access to the chatops bot. Chatops bot is currently running on the ops instance,
which is different from GitLab.com or dev.gitlab.org.

Follow the Chatops document to [request access](https://docs.gitlab.com/ee/development/chatops_on_gitlabcom.html#requesting-access).

Once you are added to the project test if your access propagated,
run:

```
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

GitLab's feature library (using
[Flipper](https://github.com/jnunemaker/flipper), and covered in the [Feature
Flags process](process.md) guide) supports rolling out changes to a percentage of
users. This in turn can be controlled using [GitLab chatops](../../ci/chatops/README.md).

For an up to date list of feature flag commands please see [the source
code](https://gitlab.com/gitlab-com/chatops/blob/master/lib/chatops/commands/feature.rb).
Note that all the examples in that file must be preceded by
`/chatops run`.

If you get an error "Whoops! This action is not allowed. This incident
will be reported." that means your Slack account is not allowed to
change feature flags or you do not [have access](#access-for-enabling-a-feature-flag-in-production).

### Enabling feature for staging and dev.gitlab.org

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

## Enabling feature for GitLab.com

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
enabled for only the `gitlab-ce` project. The project is passed by supplying a
`--project` flag:

```
/chatops run feature set --project=gitlab-org/gitlab-ce some_feature true
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
See [the process document](https://docs.gitlab.com/ee/development/feature_flags/process.html#including-a-feature-behind-feature-flag-in-the-final-release) for further details.

When a feature gate has been removed from the code base, the value still exists
in the database.
This can be removed through ChatOps:

```
/chatops run feature delete some_feature
```
