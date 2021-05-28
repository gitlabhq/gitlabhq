---
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
type: reference
description: "GitLab administrator: enable and disable GitLab features deployed behind feature flags"
---

# Enable and disable GitLab features deployed behind feature flags **(FREE SELF)**

GitLab adopted [feature flags strategies](../development/feature_flags/index.md)
to deploy features in an early stage of development so that they can be
incrementally rolled out.

Before making them permanently available, features can be deployed behind
flags for a [number of reasons](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags), such as:

- To test the feature.
- To get feedback from users and customers while in an early stage of the development of the feature.
- To evaluate users adoption.
- To evaluate how it impacts the performance of GitLab.
- To build it in smaller pieces throughout releases.

Features behind flags can be gradually rolled out, typically:

1. The feature starts disabled by default.
1. The feature becomes enabled by default.
1. The feature flag is removed.

These features can be enabled and disabled to allow or disallow users to use
them. It can be done by GitLab administrators with access to GitLab Rails
console.

If you used a certain feature and identified a bug, a misbehavior, or an
error, it's very important that you [**provide feedback**](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Docs%20-%20feature%20flag%20feedback%3A%20Feature%20Name&issue[description]=Describe%20the%20problem%20you%27ve%20encountered.%0A%0A%3C!--%20Don%27t%20edit%20below%20this%20line%20--%3E%0A%0A%2Flabel%20~%22docs%5C-comments%22%20) to GitLab as soon
as possible so we can improve or fix it while behind a flag. When you upgrade
GitLab to an earlier version, the feature flag status may change.

WARNING:
Features deployed behind feature flags may not be ready for
production use. However, disabling features behind flags that were deployed
enabled by default may also present a risk. If they're enabled, we recommend
you leave them as-is.

## How to enable and disable features behind flags

Each feature has its own flag that should be used to enable and disable it.
The documentation of each feature behind a flag includes a section informing
the status of the flag and the command to enable or disable it.

### Start the GitLab Rails console

The first thing you need to enable or disable a feature behind a flag is to
start a session on GitLab Rails console.

For Omnibus installations:

```shell
sudo gitlab-rails console
```

For installations from the source:

```shell
sudo -u git -H bundle exec rails console -e production
```

For details, see [starting a Rails console session](operations/rails_console.md#starting-a-rails-console-session).

### Enable or disable the feature

Once the Rails console session has started, run the `Feature.enable` or
`Feature.disable` commands accordingly. The specific flag can be found
in the feature's documentation itself.

To enable a feature, run:

```ruby
Feature.enable(:<feature flag>)
```

Example, to enable a fictional feature flag named `my_awesome_feature`:

```ruby
Feature.enable(:my_awesome_feature)
```

To disable a feature, run:

```ruby
Feature.disable(:<feature flag>)
```

Example, to disable a fictional feature flag named `my_awesome_feature`:

```ruby
Feature.disable(:my_awesome_feature)
```

Some feature flags can be enabled or disabled on a per project basis:

```ruby
Feature.enable(:<feature flag>, Project.find(<project id>))
```

For example, to enable the [`:product_analytics`](../operations/product_analytics.md#enable-or-disable-product-analytics) feature flag for project `1234`:

```ruby
Feature.enable(:product_analytics, Project.find(1234))
```

`Feature.enable` and `Feature.disable` always return `nil`, this is not an indication that the command failed:

```ruby
irb(main):001:0> Feature.enable(:my_awesome_feature)
=> nil
```

To check if a flag is enabled or disabled you can use `Feature.enabled?` or `Feature.disabled?`. For example, for a fictional feature flag named `my_awesome_feature`:

```ruby
Feature.enable(:my_awesome_feature)
=> nil
Feature.enabled?(:my_awesome_feature)
=> true
Feature.disabled?(:my_awesome_feature)
=> false
```

When the feature is ready, GitLab removes the feature flag, and the option for
enabling and disabling it no longer exists. The feature becomes available in all instances.
