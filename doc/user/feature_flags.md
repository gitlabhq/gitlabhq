---
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "Understand what 'GitLab features deployed behind flags' means."
layout: 'feature_flags'
---

# GitLab functionality may be limited by feature flags

> Feature flag documentation warnings were [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227806) in GitLab 13.4.

GitLab releases some features in a disabled state using [feature flags](../development/feature_flags/index.md),
allowing them to be tested by specific groups of users and strategically
rolled out until they become enabled for everyone.

As a GitLab user, this means that some features included in a GitLab release
may be unavailable to you.

In this case, you'll see a warning like this in the feature documentation:

This in-development feature might not be available for your use. There can be
[risks when enabling features still in development](../administration/feature_flags.md#risks-when-enabling-features-still-in-development).
Refer to this feature's version history for more details.

In the version history note, you'll find information on the state of the
feature flag, including whether the feature is on ("enabled by default") or
off ("disabled by default") for self-managed GitLab instances and for users of
GitLab.com.

If you're a user of a GitLab self-managed instance and you want to try to use a
disabled feature, you can ask a [GitLab administrator to enable it](../administration/feature_flags.md),
although changing a feature's default state isn't recommended.

If you're a GitLab.com user and the feature is disabled, be aware that GitLab may
be working on the feature for potential release in the future.
