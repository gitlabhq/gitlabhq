---
info: For assistance with this Style Guide page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: "GitLab development - how to document features deployed behind feature flags"
---

# Document features deployed behind feature flags

GitLab uses [feature flags](../feature_flags/index.md) to strategically roll
out the deployment of its own features. The way we document a feature behind a
feature flag depends on its state (enabled or disabled). When the state
changes, the developer who made the change **must update the documentation**
accordingly.

## When to document features behind a feature flag

Every feature introduced to the codebase, even if it's behind a disabled feature flag,
must be documented. For more information, see
[the discussion that led to this decision](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47917#note_459984428).

When the feature is [implemented over multiple merge requests](../feature_flags/index.md#feature-flags-in-gitlab-development),
discuss the exact documentation plan with your technical writer. Consider
creating a dedicated documentation issue if the feature:

- Is far-reaching (makes changes across many areas of GitLab), like navigation changes.
- Includes many MRs.
- Affects more than a few documentation pages.
- Is not fully functional if the feature flag is enabled for testing.

If you and the technical writer agree to delay the product documentation (for example, until after testing),
collaborate with the TW to create a documentation issue detailing the plan for adding the content.
The PM and EM should be included in the discussions to make sure the task of adding the documentation is assigned and scheduled.
Despite any planned delays, every feature flag in the codebase is automatically listed at
<https://docs.gitlab.com/ee/user/feature_flags.html#available-feature-flags>,
even when the feature is not fully functional.

## How to add feature flag documentation

When you document feature flags, you must:

- [Add version history text](#add-version-history-text).
- [Add a note at the start of the topic](#use-a-note-to-describe-the-state-of-the-feature-flag).

## Add version history text

When the state of a flag changes (for example, disabled by default to enabled by default), add the change to the
[version history](versions.md#add-a-version-history-item).

Possible version history entries are:

```markdown
> - [Introduced](issue-link) in GitLab X.X [with a flag](../../administration/feature_flags.md) named `flag_name`. Disabled by default.
> - [Enabled on GitLab.com](issue-link) in GitLab X.X.
> - [Enabled on GitLab.com](issue-link) in GitLab X.X. Available to GitLab.com administrators only.
> - [Enabled on self-managed](issue-link) in GitLab X.X.
> - [Generally available](issue-link) in GitLab X.Y. Feature flag `flag_name` removed.
```

You can combine entries if they happened in the same release:

```markdown
> - Introduced in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/337507) in GitLab 14.3.
```

## Use a note to describe the state of the feature flag

Information about feature flags should be in a `FLAG` note at the start of the topic (just below the version history).

The note has three parts, and follows this structure:

```markdown
FLAG:
<Self-managed GitLab availability information.>
<GitLab.com availability information.>
<This feature is not ready for production use.>
```

A `FLAG` note renders on the GitLab documentation site as:

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `example_flag`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

### Self-managed GitLab availability information

| If the feature is...     | Use this text |
|--------------------------|---------------|
| Available                | ``On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable              | ``On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available to some users  | ``On self-managed GitLab, by default this feature is available to a subset of users. To show or hide the feature for all, ask an administrator to [change the status of the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available, per-group     | ``On self-managed GitLab, by default this feature is available. To hide the feature per group, ask an administrator to [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable, per-group   | ``On self-managed GitLab, by default this feature is not available. To make it available per group, ask an administrator to [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available, per-project   | ``On self-managed GitLab, by default this feature is available. To hide the feature per project or for your entire instance, ask an administrator to [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable, per-project | ``On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available, per-user      | ``On self-managed GitLab, by default this feature is available. To hide the feature per user, ask an administrator to [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable, per-user    | ``On self-managed GitLab, by default this feature is not available. To make it available per user, ask an administrator to [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |

### GitLab.com availability information

| If the feature is...                        | Use this text |
|---------------------------------------------|---------------|
| Available                                   | `On GitLab.com, this feature is available.` |
| Available to GitLab.com administrators only | `On GitLab.com, this feature is available but can be configured by GitLab.com administrators only.`
| Unavailable                                 | `On GitLab.com, this feature is not available.`|

### Optional information

If needed, you can add this sentence:

`The feature is not ready for production use.`

## Feature flag documentation examples

The following examples show the progression of a feature flag.

```markdown
> Introduced in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `forti_token_cloud`.
The feature is not ready for production use.
```

When the feature is enabled in production, you can update the version history:

```markdown
> - Introduced in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/issue/etc) GitLab 13.8.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per user,
ask an administrator to [disable the feature flag](../administration/feature_flags.md) named `forti_token_cloud`.
```

And, when the feature is done and fully available to all users:

```markdown
> - Introduced in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/issue/etc) in GitLab 13.8.
> - [Enabled on GitLab.com](https://gitlab.com/issue/etc) in GitLab 13.9.
> - [Generally available](issue-link) in GitLab 14.0. Feature flag `forti_token_cloud` removed.
```
