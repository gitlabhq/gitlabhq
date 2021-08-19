---
type: reference, dev
info: For assistance with this Style Guide page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: "GitLab development - how to document features deployed behind feature flags"
---

# Document features deployed behind feature flags

GitLab uses [feature flags](../feature_flags/index.md) to strategically roll
out the deployment of its own features. The way we document a feature behind a
feature flag depends on its state (enabled or disabled). When the state
changes, the developer who made the change **must update the documentation**
accordingly.

Every feature introduced to the codebase, even if it's behind a feature flag,
must be documented. For context, see the
[latest merge request that updated this guideline](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47917#note_459984428).

When you document feature flags, you must:

- [Add a note at the start of the topic](#use-a-note-to-describe-the-state-of-the-feature-flag).
- [Add version history text](#add-version-history-text).

## Use a note to describe the state of the feature flag

Information about feature flags should be in a **Note** at the start of the topic (just below the version history).

The note has three parts, and follows this structure:

```markdown
FLAG:
<Self-managed GitLab availability information.> <GitLab.com availability information.>
<This feature is not ready for production use.>
```

### Self-managed GitLab availability information

| If the feature is...     | Use this text |
|--------------------------|---------------|
| Available                | `On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the <flag name> flag](<path to>/administration/feature_flags.md).` |
| Unavailable              | `On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the <flag name> flag](<path to>/administration/feature_flags.md).` |
| Available, per-group     | `On self-managed GitLab, by default this feature is available. To hide the feature per group, ask an administrator to [disable the <flag name> flag](<path to>/administration/feature_flags.md).` |
| Unavailable, per-group   | `On self-managed GitLab, by default this feature is not available. To make it available per group, ask an administrator to [enable the <flag name> flag](<path to>/administration/feature_flags.md).` |
| Available, per-project   | `On self-managed GitLab, by default this feature is available. To hide the feature per project or for your entire instance, ask an administrator to [disable the <flag name> flag](<path to>/administration/feature_flags.md).` |
| Unavailable, per-project | `On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the <flag name> flag](<path to>/administration/feature_flags.md).` |
| Available, per-user      | `On self-managed GitLab, by default this feature is available. To hide the feature per user, ask an administrator to [disable the <flag name> flag](<path to>/administration/feature_flags.md).` |
| Unavailable, per-user    | `On self-managed GitLab, by default this feature is not available. To make it available per user, ask an administrator to [enable the <flag name> flag](<path to>/administration/feature_flags.md).` |

### GitLab.com availability information

| If the feature is...                | Use this text |
|-------------------------------------|---------------|
| Available                           | `On GitLab.com, this feature is available.` |
| Available to GitLab.com admins only | `On GitLab.com, this feature is available but can be configured by GitLab.com administrators only.`
| Unavailable                         | `On GitLab.com, this feature is not available.`|

### Optional information

If needed, you can add this sentence:

`You should not use this feature for production environments.`

## Add version history text

When the state of a flag changes (for example, disabled by default to enabled by default), add the change to the version history.

Possible version history entries are:

```markdown
> - [Enabled on GitLab.com](issue-link) in GitLab X.X and is ready for production use.
> - [Enabled on GitLab.com](issue-link) in GitLab X.X and is ready for production use. Available to GitLab.com administrators only.
> - [Enabled with <flag name> flag](issue-link) for self-managed GitLab in GitLab X.X and is ready for production use.
> - [Feature flag <flag name> removed](issue-line) in GitLab X.X.
```

## Feature flag documentation examples

The following examples show the progression of a feature flag.

```markdown
> Introduced in GitLab 13.7.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the `forti_token_cloud` flag](../administration/feature_flags.md).`
The feature is not ready for production use.
```

If it were to be updated in the future to enable its use in production, you can update the version history:

```markdown
> - Introduced in GitLab 13.7.
> - [Enabled with `forti_token_cloud` flag](https://gitlab.com/issue/etc) for self-managed GitLab in GitLab X.X and ready for production use.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per user,
ask an administrator to [disable the `forti_token_cloud` flag](../administration/feature_flags.md).
```

And, when the feature is done and fully available to all users:

```markdown
> - Introduced in GitLab 13.7.
> - [Enabled on GitLab.com](https://gitlab.com/issue/etc) in GitLab X.X and is ready for production use.
> - [Enabled with `forti_token_cloud` flag](https://gitlab.com/issue/etc) for self-managed GitLab in GitLab X.X and is ready for production use.
> - [Feature flag `forti_token_cloud`](https://gitlab.com/issue/etc) removed in GitLab X.X.
```
