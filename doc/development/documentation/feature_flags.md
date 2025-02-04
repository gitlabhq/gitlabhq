---
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
stage: none
group: unassigned
description: "GitLab development - how to document features deployed behind feature flags"
title: Document features deployed behind feature flags
---

GitLab uses [feature flags](../feature_flags/_index.md) to roll
out the deployment of its own features.

When the state of a feature flag changes, the developer who made the change
**must update the documentation**.

## When to document features behind a feature flag

Every feature introduced to the codebase, even if it's behind a disabled flag,
must be documented. For more information, see
[the discussion that led to this decision](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47917#note_459984428). [Experiment and beta](../../policy/development_stages_support.md) features are usually behind a flag and must also be documented. For more information, see [Document experiment or beta features](experiment_beta.md).

When the feature is [implemented in multiple merge requests](../feature_flags/_index.md#feature-flags-in-gitlab-development),
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

To document feature flags:

- [Add history text](#add-history-text).
- [Add a flag note](#add-a-flag-note).

## Offerings

When documenting the [offerings](styleguide/availability_details.md#offering), for features
**disabled on GitLab Self-Managed**, don't list `GitLab Dedicated` as the feature's offering.

## Add history text

When the state of a flag changes (for example, from disabled by default to enabled by default), add the change to the
[history](../documentation/styleguide/availability_details.md#history).

Possible history entries are:

```markdown
> - [Introduced](https://issue-link) in GitLab X.X [with a flag](../../administration/feature_flags.md) named `flag_name`. Disabled by default.
> - [Enabled on GitLab.com](https://issue-link) in GitLab X.X.
> - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab X.X.
> - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://issue-link) in GitLab X.X.
> - [Generally available](https://issue-link) in GitLab X.Y. Feature flag `flag_name` removed.
```

These entries might not fit every scenario. You can adjust to suit your needs.
For example, a flag might be enabled for a group, project, or subset of users only.
In that case, you can use a history entry like:

`> - [Enabled on GitLab.com](https://issue-link) in GitLab X.X for a subset of users.`

## Add a flag note

Add this feature flag note at the start of the topic, just below the history.

The final sentence (`not ready for production use`) is optional.

```markdown
FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.
```

This note renders on the GitLab documentation site as:

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

## History examples

The following examples show the progression of a feature flag. Update the history with every change:

```markdown
> - [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag. For more information, see the history.
```

When the feature is enabled by default on GitLab.com:

```markdown
> - [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on GitLab.com](https://issue-link) in GitLab 13.8.

FLAG:
The availability of this feature is controlled by a feature flag. For more information, see the history.
```

When the feature is enabled by default for all offerings:

```markdown
> - [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on GitLab.com](https://issue-link) in GitLab 13.8.
> - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 13.9.

FLAG:
The availability of this feature is controlled by a feature flag. For more information, see the history.
```

When the flag is removed, add a `Generally available` entry. Ensure that you delete the `FLAG` note as well:

```markdown
> - [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
> - [Enabled on GitLab.com](https://issue-link) in GitLab 13.8.
> - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 13.9.
> - [Generally available](https://issue-link) in GitLab 14.0. Feature flag `forti_token_cloud` removed.
```

## Simplify long history

The history can get long, but you can sometimes simplify or delete entries.

Combine entries if they happened in the same release:

- Before:

  ```markdown
  > - [Introduced](https://issue-link) in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
  > - [Enabled on GitLab.com](https://issue-link) in GitLab 14.3.
  > - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 14.3.
  ```

- After:

  ```markdown
  > - [Introduced](https://issue-link) in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
  > - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://issue-link) in GitLab 14.3.
  ```

If the feature flag is introduced and enabled in the same release, combine the entries:

```markdown
> - [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Enabled by default.
```

Delete `Enabled on GitLab.com` entries only when the feature is enabled by default for all offerings and the flag is removed:

- Before:

  ```markdown
  > - [Introduced](https://issue-link) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
  > - [Enabled on GitLab.com](https://issue-link) in GitLab 15.7.
  > - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 15.8.
  > - [Generally available](https://issue-link) in GitLab 15.9. Feature flag `ci_hooks_pre_get_sources_script` removed.
  ```

- After:

  ```markdown
  > - [Introduced](https://issue-link) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
  > - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 15.8.
  > - [Generally available](https://issue-link) in GitLab 15.9. Feature flag `ci_hooks_pre_get_sources_script` removed.
  ```
