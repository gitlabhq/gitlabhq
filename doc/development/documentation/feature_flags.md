---
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: "GitLab development - how to document features deployed behind feature flags"
---

# Document features deployed behind feature flags

GitLab uses [feature flags](../feature_flags/index.md) to roll
out the deployment of its own features.

When the state of a feature flag changes, the developer who made the change
**must update the documentation**.

## When to document features behind a feature flag

Every feature introduced to the codebase, even if it's behind a disabled flag,
must be documented. For more information, see
[the discussion that led to this decision](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47917#note_459984428). [Experiment or Beta](../../policy/experiment-beta-support.md) features are usually behind a flag and must also be documented. For more information, see [Document Experiment or Beta features](experiment_beta.md).

When the feature is [implemented in multiple merge requests](../feature_flags/index.md#feature-flags-in-gitlab-development),
discuss the plan with your technical writer.

You can create a documentation issue and delay the documentation if the feature:

- Is far-reaching (makes changes across many areas of GitLab), like navigation changes.
- Includes many MRs.
- Affects more than a few documentation pages.
- Is not fully functional if the feature flag is enabled for testing.

The PM, EM, and writer should make sure the documentation work is assigned and scheduled.

Every feature flag in the codebase is [in the documentation](../../user/feature_flags.md),
even when the feature is not fully functional or otherwise documented.

## How to add feature flag documentation

When you document feature flags, you must:

- [Add history text](#add-history-text).
- [Use a note to describe the state of the feature flag](#use-a-note-to-describe-the-state-of-the-feature-flag).

## Add history text

When the state of a flag changes (for example, from disabled by default to enabled by default), add the change to the
[history](versions.md#add-a-history-item).

Possible history entries are:

```markdown
> - [Introduced](issue-link) in GitLab X.X [with a flag](../../administration/feature_flags.md) named `flag_name`. Disabled by default.
> - [Enabled on self-managed](issue-link) in GitLab X.X.
> - [Enabled on GitLab.com](issue-link) in GitLab X.X.
> - [Enabled on GitLab Dedicated](issue-link) in GitLab X.X.
> - [Generally available](issue-link) in GitLab X.Y. Feature flag `flag_name` removed.
```

## Use a note to describe the state of the feature flag

Information about feature flags should be in a `FLAG` note at the start of the topic (just below the history).

The note has three required parts and one optional part.
The note follows this exact structure and order:

```markdown
FLAG:
<Self-managed GitLab availability information.>
<GitLab.com availability information.>
<GitLab Dedicated availability information.>
<This feature is not ready for production use.>
```

A `FLAG` note renders on the GitLab documentation site as:

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `example_flag`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

### Self-managed GitLab availability information

| If the feature is...     | Use this text |
|--------------------------|---------------|
| Available                | ``On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable              | ``On self-managed GitLab, by default this feature is not available. To make it available, an administrator can [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available to some users  | ``On self-managed GitLab, by default this feature is available to a subset of users. To show or hide the feature for all, an administrator can [change the status of the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available, per-group     | ``On self-managed GitLab, by default this feature is available. To hide the feature per group, an administrator can [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable, per-group   | ``On self-managed GitLab, by default this feature is not available. To make it available per group, an administrator can [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available, per-project   | ``On self-managed GitLab, by default this feature is available. To hide the feature per project or for your entire instance, an administrator can [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable, per-project | ``On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, an administrator can [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Available, per-user      | ``On self-managed GitLab, by default this feature is available. To hide the feature per user, an administrator can [disable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |
| Unavailable, per-user    | ``On self-managed GitLab, by default this feature is not available. To make it available per user, an administrator can [enable the feature flag](<path to>/administration/feature_flags.md) named `flag_name`.`` |

### GitLab.com availability information

| If the feature is...                        | Use this text |
|---------------------------------------------|---------------|
| Available                                   | `On GitLab.com, this feature is available.` |
| Available to GitLab.com administrators only | `On GitLab.com, this feature is available but can be configured by GitLab.com administrators only.` |
| Unavailable                                 | `On GitLab.com, this feature is not available.` |

### GitLab Dedicated availability information

| If the feature is...                        | Use this text |
|---------------------------------------------|---------------|
| Available                                   | `On GitLab Dedicated, this feature is available.` |
| Unavailable                                 | `On GitLab Dedicated, this feature is not available.` |

- You can combine GitLab.com and GitLab Dedicated like this:
  `On GitLab.com and GitLab Dedicated, this feature is not available.`
- If the feature is behind a flag that is disabled for self-managed GitLab,
  the feature is not available for GitLab Dedicated.

### Optional information

If needed, you can add this sentence:

`This feature is not ready for production use.`

## Feature flag documentation examples

The following examples show the progression of a feature flag. Update the history and the `FLAG` note with every change:

```markdown
> - [Introduced](issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can [enable the feature flag](../administration/feature_flags.md) named `forti_token_cloud`.
On GitLab.com and GitLab Dedicated, this feature is not available.
```

When the feature is enabled by default on self-managed and GitLab Dedicated:

```markdown
> - [Introduced](issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on self-managed and GitLab Dedicated](issue-link) in GitLab 13.8.

FLAG:
On self-managed GitLab, by default this feature is available.
To hide the feature, an administrator can [disable the feature flag](../administration/feature_flags.md) named `forti_token_cloud`.
On GitLab.com, this feature is not available. On GitLab Dedicated, this feature is available.
```

When the feature is enabled by default for all offerings:

```markdown
> - [Introduced](issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on self-managed and GitLab Dedicated](issue-link) in GitLab 13.8.
> - [Enabled on GitLab.com](issue-link) in GitLab 13.9.

FLAG:
On self-managed GitLab, by default this feature is available.
To hide the feature, an administrator can [disable the feature flag](../administration/feature_flags.md) named `forti_token_cloud`.
On GitLab.com and GitLab Dedicated, this feature is available.
```

When the flag is removed, add the `Generally available` entry and delete the `FLAG` note:

```markdown
> - [Introduced](issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on self-managed and GitLab Dedicated](issue-link) in GitLab 13.8.
> - [Enabled on GitLab.com](issue-link) in GitLab 13.9.
> - [Generally available](issue-link) in GitLab 14.0. Feature flag `forti_token_cloud` removed.
```

## Simplify long history

The history can get long, but you can sometimes simplify or delete entries.

Combine entries if they happened in the same release:

- Before:

  ```markdown
  > - [Introduced](issue-link) in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
  > - [Enabled on self-managed](issue-link) in GitLab 14.3.
  > - [Enabled on GitLab.com](issue-link) in GitLab 14.3.
  > - [Enabled on GitLab Dedicated](issue-link) in GitLab 14.3.
  ```

- After:

  ```markdown
  > - [Introduced](issue-link) in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
  > - [Enabled on self-managed, GitLab.com, and GitLab Dedicated](issue-link) in GitLab 14.3.
  ```

Delete `Enabled on GitLab.com` entries only when the feature is enabled by default for all offerings and the flag is removed:

- Before:

  ```markdown
  > - [Introduced](issue-link) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
  > - [Enabled on self-managed and GitLab Dedicated](issue-link) in GitLab 15.7.
  > - [Enabled on GitLab.com](issue-link) in GitLab 15.8.
  > - [Generally available](issue-link) in GitLab 15.9. Feature flag `ci_hooks_pre_get_sources_script` removed.
  ```

- After:

  ```markdown
  > - [Introduced](issue-link) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
  > - [Enabled on self-managed and GitLab Dedicated](issue-link) in GitLab 15.7.
  > - [Generally available](issue-link) in GitLab 15.9. Feature flag `ci_hooks_pre_get_sources_script` removed.
  ```
