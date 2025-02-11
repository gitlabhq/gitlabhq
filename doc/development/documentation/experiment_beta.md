---
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects
stage: none
group: unassigned
title: Documenting experimental and beta features
---

When you document an [experiment or beta](../../policy/development_stages_support.md) feature:

- Include the status in the [product availability details](styleguide/availability_details.md#status).
- Include [feature flag details](feature_flags.md) if behind a feature flag.
- [Update the feature status](styleguide/availability_details.md#changed-feature-status) when it changes.

## When features become generally available

When the feature changes from experiment or beta to generally available:

- Remove the **Status** from the product availability details.
- Remove any language about the feature not being ready for production.
- Update the [history](../documentation/styleguide/availability_details.md#history).

## Features that require user enrollment or feedback

To include details about how users should enroll or leave feedback,
add it below the `FLAG:` note.

For example:

```markdown
## Great new feature

DETAILS:
**Status:** Experiment

> - [Introduced](https://issue-link) in GitLab 15.10. This feature is an [experiment](<link_to>/policy/development_stages_support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Use this new feature when you need to do this new thing.

This feature is an [experiment](<link_to>/policy/development_stages_support.md). To join
the list of users testing this feature, do this thing. If you find a bug,
[open an issue](https://link).
```

## GitLab Duo features

Follow these guidelines when you document GitLab Duo features.

### Experiment

When documenting a GitLab Duo experiment:

- On the [top-level GitLab Duo page](../../user/gitlab_duo/_index.md), add a topic to the
  `Experimental features` section.
- Document the feature near other similar features.
- Make sure you add history and status values, including any
  [add-on information](styleguide/availability_details.md#gitlab-duo-pro-or-enterprise-add-on).
- For features that are part of the [Early Access Program](../../policy/early_access_program/_index.md#add-a-feature-to-the-program)
  in the `#developer-relations-early-access-program` Slack channel,
  post a comment that mentions the feature and its status.

### Beta

When a GitLab Duo experiment moves to beta:

- On the [top-level GitLab Duo page](../../user/gitlab_duo/_index.md), move the topic from the
  `Experimental features` to the `Beta features` section.
- Make sure you update the history and status values, including any
  [add-on information](styleguide/availability_details.md#gitlab-duo-pro-or-enterprise-add-on).
- For features that are part of the [Early Access Program](../../policy/early_access_program/_index.md#add-a-feature-to-the-program)
  in the `#developer-relations-early-access-program` Slack channel,
  post a comment that mentions the feature and its status.

### Generally available

When a GitLab Duo feature becomes generally available:

- On the [top-level GitLab Duo page](../../user/gitlab_duo/_index.md), move the topic from the
  `Beta features` or `Experimental features` section to the `Generally available features` section.
- Make sure you update the history and status values, including any
  [add-on information](styleguide/availability_details.md#gitlab-duo-pro-or-enterprise-add-on).
- For features that are part of the [Early Access Program](../../policy/early_access_program/_index.md#add-a-feature-to-the-program)
  in the `#developer-relations-early-access-program` Slack channel,
  post a comment that mentions the feature and its status.
