---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure large language models for GitLab Duo features.
title: GitLab Duo (Classic) AI models
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Every GitLab Duo (Classic) feature uses a default model. GitLab might update default models to optimize performance. You can select a different model for a feature, which persists until you change it.

## Default models

The following table lists the default model for each GitLab Duo feature.

| Feature | Model |
|---------|---------------|
| **Code Suggestions** | |
| Code Generation | Claude Sonnet 4 Vertex |
| Code Completion | Codestral 25.01 Fireworks|
| **GitLab Duo Chat** | |
| General Chat | Claude Sonnet 4.5 Vertex |
| Code Explanation | Claude Sonnet 4 |
| Test Generation | Claude Sonnet 4.5 Vertex |
| Refactor Code | Claude Sonnet 4.5 Vertex |
| Fix Code | Claude Sonnet 4.5 Vertex |
| Root Cause Analysis | Claude Sonnet 4 Vertex |
| **GitLab Duo for merge requests** | |
| Merge Commit Message Generation | Claude Sonnet 4 Vertex|
| Merge Request Summary | Claude Sonnet 4 Vertex |
| Code Review Summary | Claude Sonnet 4 Vertex |
| Code Review | Claude Sonnet 4 Vertex |
| **Other GitLab Duo features** | |
| Vulnerability Explanation | Claude Sonnet 4.5 Vertex |
| Vulnerability Resolution | Claude Sonnet 4.5 |
| Discussion Summary | Claude Sonnet 4.5 Vertex |
| GitLab Duo for CLI | Claude Haiku 4.5 |

## Supported models

The following tables list the models you can select for each feature.

### Code Suggestions

| Model | Code Generation | Code Completion |
|------------|-----------------|-----------------|
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} |
| Codestral 25.01 Fireworks | {{< no >}} | {{< yes >}} |
| Codestral 25.01 Vertex | {{< no >}} | {{< yes >}} |
| Codestral 25.08 Fireworks| {{< no >}} | {{< yes >}} |
| Codestral 25.08 Vertex| {{< no >}} | {{< yes >}} |
| Gemini 2.5 Flash | {{< yes >}} | {{< no >}} |

### GitLab Duo Chat (Classic)

| Model | General Chat | Code Explanation | Test Generation | Refactor Code | Fix Code | Root Cause Analysis |
|------------|--------------|------------------|-----------------|---------------|----------|---------------------|
| Claude Haiku 4.5 | {{< yes >}} | {{< no >}} | | | {{< no >}} | |
| Claude Sonnet 3 | {{< no >}} | | | {{< no >}} | | {{< yes >}} |
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |  |

### GitLab Duo for merge requests

| Model | Merge Commit Message Generation | Merge Request Summary | Code Review Summary | Code Review |
|------------|--------------------------------|------------------------|---------------------|-------------|
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |

### Other GitLab Duo features

| Model | Vulnerability Explanation | Vulnerability Resolution | GitLab Duo for CLI | Discussion Summary |
|------------|----------------------------|--------------------------|-------------------|---------------------|
| Claude Haiku 3 | {{< yes >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| Claude Haiku 4.5 | {{< no >}} | | {{< yes >}} | {{< no >}} |
| Claude Sonnet 4 |  | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} |  | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} |  |  | {{< yes >}} |

## Select a model for a feature

{{< details >}}

- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17570) for top-level groups in GitLab 18.1 with a [flag](../../administration/feature_flags/_index.md) named `ai_model_switching`. Disabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) to beta in GitLab 18.4.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) in GitLab 18.4.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/18818) in GitLab 18.5. Feature flag `ai_model_switching` enabled.
- Feature flag `ai_model_switching` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) in GitLab 18.7.

{{< /history >}}

You can select a model for a feature in a top-level group. The model that you select
applies to that feature for all child groups and projects.

Prerequisites:

- You have the Owner role for the group.
- The group that you select models for is a top-level group.
- In GitLab 18.3 or later, if you belong to multiple GitLab Duo namespaces, you must [assign a default namespace](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace).

To select a model for a feature:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Configure features**.
1. For the feature you want to configure, select a model from the dropdown list.
1. Optional. To apply the model to all features in the section, select **Apply to all**.

## Troubleshooting

When selecting models other than the default, you might encounter the following issues.

### Model is not available

If you are using the default GitLab model for a GitLab Duo AI-native feature, GitLab might change the default model without notifying the user to maintain optimal performance and reliability.

If you have selected a specific model for a GitLab Duo AI-native feature, and that model is not available, there is no automatic fallback. The feature that uses this model is unavailable.

### No default GitLab Duo namespace

When using a GitLab Duo feature with a selected model, you might get an error that states that you have not selected a default GitLab Duo namespace. For example, on:

- GitLab Duo Code Suggestions, you might get `Error 422: No default Duo group found. Select a default Duo group in your user preferences and try again.`
- GitLab Duo Chat, you might get `Error G3002: I'm sorry, you have not selected a default GitLab Duo namespace. Please go to GitLab and in user Preferences - Behavior, select a default namespace for GitLab Duo.`

This issue occurs when you belong to multiple GitLab Duo namespaces, but have not chosen one as your default namespace.

To resolve this, [set a default GitLab Duo namespace](../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace).
