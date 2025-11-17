---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects
title: Documenting experimental and beta features
---

When you document an [experiment or beta](../../policy/development_stages_support.md) feature:

- Include the status in the [product availability details](styleguide/availability_details.md#status).
- Include [feature flag details](feature_flags.md) if behind a feature flag.
- [Update the feature status](styleguide/availability_details.md#changed-feature-status) when it changes.

## Experiment and beta feature toggles

The **Use experiment and beta features** toggle in namespace settings is specifically for
[GitLab Duo features](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) only.
This setting should not be used for non-AI/Duo experiment or beta features.

For non-Duo experiment and beta features:

- Use feature-specific toggles or feature flags appropriate to your feature.
- Do not tie your feature to the namespace-level experiment and beta setting.
- Document the specific controls for your feature in its own documentation.

### Settings by GitLab instance type

There are two different settings that control experiment and beta features for GitLab Duo,
depending on the type of GitLab instance:

- **GitLab.com (SaaS)**: Uses the top-level namespace setting `experiment_features_enabled`.
  This is a namespace-level setting that allows each top-level group to control whether
  experiment and beta GitLab Duo features are enabled for their namespace.

- **GitLab Self-Managed and GitLab Dedicated**: Uses the instance-level setting
  `instance_level_ai_beta_features_enabled`. This is an instance-wide setting controlled
  by administrators that applies to all namespaces on the instance.

When implementing GitLab Duo features:

- Check the appropriate setting based on the instance type.
- On GitLab.com, check the namespace's `experiment_features_enabled` setting.
- On Self-Managed and Dedicated instances, check the `instance_level_ai_beta_features_enabled` setting.
- Do not mix these settings or check both - each instance type should only use its relevant setting.

For implementation examples, see [`ee/lib/gitlab/llm/stage_check.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/llm/stage_check.rb).

## When features become generally available

When the feature changes from experiment or beta to generally available:

- Remove the **Status** from the product availability details.
- Remove any language about the feature not being ready for production.
- Update the [history](styleguide/availability_details.md#history).

## Features that require user enrollment or feedback

To include details about how users should enroll or leave feedback,
add it below the `type=flag` alert.

For example:

```markdown
## Great new feature

{{</* details */>}}

Status: Experiment

{{</* /details */>}}

{{</* history */>}}

- [Introduced](https://issue-link) in GitLab 15.10. This feature is an [experiment](<link_to>/policy/development_stages_support.md).

{{</* /history */>}}

{{</* alert type="flag" */>}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{</* /alert */>}}

Use this new feature when you need to do this new thing.

This feature is an [experiment](<link_to>/policy/development_stages_support.md).
To test this feature, do this thing or contact these people.

Provide feedback [in issue 12345](https://link).
```

## GitLab Duo features

Follow these guidelines when you document GitLab Duo features.

### Experiment

When documenting a GitLab Duo experiment:

- On the [GitLab Duo feature summary page](../../user/gitlab_duo/feature_summary.md):
  - Add a row to the table.
  - Add the feature to an area at the top of the page, near other features that are available
    during a similar stage of the software development lifecycle.
- Document the feature near other similar features.
- Make sure you add history and status values, including any
  [add-on information](styleguide/availability_details.md#add-ons).
- For features that are part of the [Early Access Program](../../policy/early_access_program/_index.md#add-a-feature-to-the-program)
  in the `#developer-relations-early-access-program` Slack channel,
  post a comment that mentions the feature and its status.

### Beta

When a GitLab Duo experiment moves to beta:

- On the [GitLab Duo feature summary page](../../user/gitlab_duo/feature_summary.md),
  update the row in the table.
- Make sure you update the history and status values, including any
  [add-on information](styleguide/availability_details.md#add-ons).
- For features that are part of the [Early Access Program](../../policy/early_access_program/_index.md#add-a-feature-to-the-program)
  in the `#developer-relations-early-access-program` Slack channel,
  post a comment that mentions the feature and its status.

### Generally available

When a GitLab Duo feature becomes generally available:

- On the [GitLab Duo feature summary page](../../user/gitlab_duo/feature_summary.md),
  move the feature to the GA table.
- Make sure you update the history and status values, including any
  [add-on information](styleguide/availability_details.md#add-ons).
- For features that are part of the [Early Access Program](../../policy/early_access_program/_index.md#add-a-feature-to-the-program)
  in the `#developer-relations-early-access-program` Slack channel,
  post a comment that mentions the feature and its status.
