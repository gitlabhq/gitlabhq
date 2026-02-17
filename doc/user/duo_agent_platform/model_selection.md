---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure large language models for GitLab Duo features.
title: Agent Platform AI models
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Every GitLab Duo feature uses a default model. GitLab might update default models to optimize performance. For some features, you can select a different model, which persists until you change it.

## Default models

This table lists the default model for each feature in the Agent Platform.

| Feature | Model |
|-------|--------------|
| GitLab Duo Chat (Agentic) | Claude Haiku 4.5 |
| All other agents | Claude Sonnet 4.5 Vertex |

## Supported models

This table lists the models you can select for features
in the Agent Platform.

> [!note]
> The OpenAI models used in GitLab Duo Chat (Agentic) have experimental support, specifically for GPT-5, GPT-5 mini, and GPT-5-Codex.
> Share your feedback about OpenAI models in GitLab Duo Chat (Agentic) in this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/572864).

| Model | Agentic Chat | All other agents |
|-------|--------------|------------------|
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} | {{< yes >}} |
| Claude Haiku 4.5 | {{< yes >}} | {{< yes >}} |
| Claude Opus 4.5 | {{< yes >}} | {{< yes >}} |
| Claude Opus 4.6 | {{< yes >}} | {{< yes >}} |
| GPT-5 | {{< yes >}} | {{< yes >}} |
| GPT-5 Codex | {{< yes >}} | {{< yes >}} |
| GPT-5 Mini | {{< yes >}} | {{< yes >}} |
| GPT-5.2 | {{< yes >}} | {{< yes >}} |

## Select a model for a feature

{{< details >}}

- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17570) for top-level groups in GitLab 18.1 with a [flag](../../administration/feature_flags/_index.md) named `ai_model_switching`. Disabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) to beta in GitLab 18.4.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) in GitLab 18.4.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/568112) model selection for GitLab Duo Agent Platform in GitLab 18.4 with a [flag](../../administration/feature_flags/_index.md) called `duo_agent_platform_model_selection`. Disabled by default.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/18818) in GitLab 18.5. Feature flag `ai_model_switching` enabled.
- Feature flag `duo_agent_platform_model_selection` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051) in GitLab 18.6.
- Feature flag `ai_model_switching` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) in GitLab 18.7.
- Feature flag `duo_agent_platform_model_selection` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/218591) in GitLab 18.9.

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
1. Go to the **GitLab Duo Agent Platform** section.
1. Select a model from the dropdown list.
1. Optional. To apply the model to all features in the section, select **Apply to all**.

In the IDE, model selection for GitLab Duo Chat (Agentic) is applied only when the connection type is set to WebSocket.

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
