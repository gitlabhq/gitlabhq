---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: GitLab development - how to document features deployed behind feature flags
title: Document features deployed behind feature flags
---

GitLab uses [feature flags](../feature_flags/_index.md) to roll
out the deployment of its own features.

{{< alert type="note" >}}

The developer who changes the state of a feature flag is responsible for
updating the documentation.

{{< /alert >}}

## When to document features behind a feature flag

Before a feature flag is enabled for all customers in an environment (GitLab Self-Managed, GitLab.com, or GitLab Dedicated),
the feature must be documented.

For all other features behind flags, the PM or EM for the group determines whether or not
to document the feature.

Even when a flag is not documented alongside the feature, it is
[automatically documented on a central page](../../user/feature_flags.md).

## How to add feature flag documentation

To document feature flags:

- [Add history text](#add-history-text).
- [Add a flag note](#add-a-flag-note).

## Offerings

When documenting the [offerings](styleguide/availability_details.md#offering), for features
**disabled on GitLab Self-Managed**, don't list `GitLab Dedicated` as the feature's offering.

## Add history text

When the state of a flag changes (for example, from disabled by default to enabled by default), add the change to the
[history](styleguide/availability_details.md#history).

Possible history entries are:

```markdown
- [Introduced](https://issue-link) in GitLab X.X [with a flag](../../administration/feature_flags.md) named `flag_name`. Disabled by default.
- [Enabled on GitLab.com](https://issue-link) in GitLab X.X.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab X.X.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://issue-link) in GitLab X.X.
- [Generally available](https://issue-link) in GitLab X.Y. Feature flag `flag_name` removed.
```

These entries might not fit every scenario. You can adjust to suit your needs.
For example, a flag might be enabled for a group, project, or subset of users only.
In that case, you can use a history entry like:

`- [Enabled on GitLab.com](https://issue-link) in GitLab X.X for a subset of users.`

## Add a flag note

Add this feature flag note at the start of the topic, just below the history.

The final sentence (`not ready for production use`) is optional.

```markdown
{{</* alert type="flag" */>}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{</* /alert */>}}
```

This note renders on the GitLab documentation site as:

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

## History examples

The following examples show the progression of a feature flag. Update the history with every change:

```markdown
{{</* history */>}}

- [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.

{{</* /history */>}}

{{</* alert type="flag" */>}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{</* /alert */>}}
```

When the feature is enabled by default on GitLab.com:

```markdown
{{</* history */>}}

- [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
- [Enabled on GitLab.com](https://issue-link) in GitLab 13.8.

{{</* /history */>}}

{{</* alert type="flag" */>}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{</* /alert */>}}
```

When the feature is enabled by default for all offerings:

```markdown
{{</* history */>}}

- [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
- [Enabled on GitLab.com](https://issue-link) in GitLab 13.8.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 13.9.

{{</* /history */>}}

{{</* alert type="flag" */>}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{</* /alert */>}}
```

When the flag is removed, add a `Generally available` entry. Ensure that you delete the `FLAG` note as well:

```markdown
{{</* history */>}}

- [Introduced](https://issue-link) in GitLab 13.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Disabled by default.
- [Enabled on GitLab.com](https://issue-link) in GitLab 13.8.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 13.9.
- [Generally available](https://issue-link) in GitLab 14.0. Feature flag `forti_token_cloud` removed.

{{</* history */>}}
```

## Simplify long history

The history can get long, but you can sometimes simplify or delete entries.

Combine entries if they happened in the same release:

- Before:

  ```markdown
  - [Introduced](https://issue-link) in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
  - [Enabled on GitLab.com](https://issue-link) in GitLab 14.3.
  - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 14.3.
  ```

- After:

  ```markdown
  - [Introduced](https://issue-link) in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ci_include_rules`. Disabled by default.
  - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://issue-link) in GitLab 14.3.
  ```

If the feature flag is introduced and enabled in the same release, combine the entries:

```markdown
- [Introduced](https://issue-link) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `forti_token_cloud`. Enabled by default.
```

Delete `Enabled on GitLab.com` entries only when the feature is enabled by default for all offerings and the flag is removed:

- Before:

  ```markdown
  {{</* history */>}}

  - [Introduced](https://issue-link) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
  - [Enabled on GitLab.com](https://issue-link) in GitLab 15.7.
  - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 15.8.
  - [Generally available](https://issue-link) in GitLab 15.9. Feature flag `ci_hooks_pre_get_sources_script` removed.

  {{</* /history */>}}
  ```

- After:

  ```markdown
  {{</* history */>}}

  - [Introduced](https://issue-link) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
  - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://issue-link) in GitLab 15.8.
  - [Generally available](https://issue-link) in GitLab 15.9. Feature flag `ci_hooks_pre_get_sources_script` removed.

  {{</* history */>}}
  ```
