---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "GitLab administrator: enable and disable GitLab features deployed behind feature flags"
title: Enable and disable GitLab features deployed behind feature flags
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab adopted [feature flags strategies](../development/feature_flags/_index.md)
to deploy features in an early stage of development so that they can be
incrementally rolled out.

Before making them permanently available, features can be deployed behind
flags for a [number of reasons](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags), such as:

- To test the feature.
- To get feedback from users and customers while in an early stage of the development of the feature.
- To evaluate users adoption.
- To evaluate how it impacts the performance of GitLab.
- To build it in smaller pieces throughout releases.

Features behind flags can be gradually rolled out, typically:

1. The feature starts disabled by default.
1. The feature becomes enabled by default.
1. The feature flag is removed.

These features can be enabled and disabled to allow or prevent users from using
them. It can be done by GitLab administrators with access to the
[Rails console](#how-to-enable-and-disable-features-behind-flags) or the
[Feature flags API](../api/features.md).

When you disable a feature flag, the feature is hidden from users and all of the functionality is turned off.
For example, data is not recorded and services do not run.

If you used a certain feature and identified a bug, a misbehavior, or an
error, it's very important that you [**provide feedback**](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Docs%20-%20feature%20flag%20feedback%3A%20Feature%20Name&issue[description]=Describe%20the%20problem%20you%27ve%20encountered.%0A%0A%3C!--%20Don%27t%20edit%20below%20this%20line%20--%3E%0A%0A%2Flabel%20~%22docs%5C-comments%22%20) to GitLab as soon
as possible so we can improve or fix it while behind a flag. When you upgrade
GitLab, the feature flag status may change.

## Risks when enabling features still in development

Before enabling a disabled feature flag in a production GitLab environment, it is crucial to understand the potential risks involved.

WARNING:
Data corruption, stability degradation, performance degradation, and security issues may occur if you enable a feature that's disabled by default.

Features that are disabled by default may change or be removed without notice in a future version of GitLab.

Features behind default-disabled feature flags are not recommended for use in a production environment
and problems caused by using a default disabled features aren't covered by GitLab Support.

Security issues found in features that are disabled by default are patched in regular releases
and do not follow our regular [maintenance policy](../policy/maintenance.md#patch-releases)
with regards to backporting the fix.

## Risks when disabling released features

In most cases, the feature flag code is removed in a future version of GitLab.
If and when that occurs, from that point onward you can't keep the feature in a disabled state.

## How to enable and disable features behind flags

Each feature has its own flag that should be used to enable and disable it.
The documentation of each feature behind a flag includes a section informing
the status of the flag and the command to enable or disable it.

### Start the GitLab Rails console

The first thing you must do to enable or disable a feature behind a flag is to
start a session on GitLab Rails console.

For Linux package installations:

```shell
sudo gitlab-rails console
```

For installations from the source:

```shell
sudo -u git -H bundle exec rails console -e production
```

For details, see [starting a Rails console session](operations/rails_console.md#starting-a-rails-console-session).

### Enable or disable the feature

After the Rails console session has started, run the `Feature.enable` or
`Feature.disable` commands accordingly. The specific flag can be found
in the feature's documentation itself.

To enable a feature, run:

```ruby
Feature.enable(:<feature flag>)
```

Example, to enable a fictional feature flag named `example_feature`:

```ruby
Feature.enable(:example_feature)
```

To disable a feature, run:

```ruby
Feature.disable(:<feature flag>)
```

Example, to disable a fictional feature flag named `example_feature`:

```ruby
Feature.disable(:example_feature)
```

Some feature flags can be enabled or disabled on a per project basis:

```ruby
Feature.enable(:<feature flag>, Project.find(<project id>))
```

For example, to enable the `:example_feature` feature flag for project `1234`:

```ruby
Feature.enable(:example_feature, Project.find(1234))
```

Some feature flags can be enabled or disabled on a per user basis. For example, to enable the `:example_feature` flag for user `sidney_jones`:

```ruby
Feature.enable(:example_feature, User.find_by_username("sidney_jones"))
```

`Feature.enable` and `Feature.disable` always return `true`, even if the application doesn't use the flag:

```ruby
irb(main):001:0> Feature.enable(:example_feature)
=> true
```

When the feature is ready, GitLab removes the feature flag, and the option for
enabling and disabling it no longer exists. The feature becomes available in all instances.

### Check if a feature flag is enabled

To check if a flag is enabled or disabled, use `Feature.enabled?` or `Feature.disabled?`.
For example, for a feature flag named `example_feature` that is already enabled:

```ruby
Feature.enabled?(:example_feature)
=> true
Feature.disabled?(:example_feature)
=> false
```

When the feature is ready, GitLab removes the feature flag, and the option for
enabling and disabling it no longer exists. The feature becomes available in all instances.

### View set feature flags

You can view all GitLab administrator set feature flags:

```ruby
Feature.all
=> [#<Flipper::Feature:198220 name="example_feature", state=:on, enabled_gate_names=[:boolean], adapter=:memoizable>]

# Nice output
Feature.all.map {|f| [f.name, f.state]}
```

### Unset feature flag

You can unset a feature flag so that GitLab falls back to the current defaults for that flag:

```ruby
Feature.remove(:example_feature)
=> true
```
