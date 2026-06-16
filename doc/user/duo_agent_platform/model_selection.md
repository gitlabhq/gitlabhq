---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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
| GitLab Duo Agentic Chat | Claude Sonnet 4.6 Vertex |
| Code Review Flow | Claude Sonnet 4.6 Vertex |
| All other agents | Claude Sonnet 4.6 Vertex |

## Supported models

This table lists the models you can select for features
in the Agent Platform.

| Model                | GitLab Duo Agentic Chat | Code Review Flow | All other agents |
|----------------------|-------------------------|------------------|------------------|
| Claude Fable 5 <sup>1</sup>      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Sonnet 4.5    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.6    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Haiku 4.5     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.5      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.6      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.7      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.8      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Gemini 3.5 Flash     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5                | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.1              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2              | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| GPT-5.5 <sup>1</sup> | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Codex          | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.3 Codex        | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| GPT-5 Mini           | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Mini         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Nano         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |

**Footnotes**:

1. This model is subject to [limited vendor-side data retention](../gitlab_duo/data_usage.md#data-retention).

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
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876) to Claude Sonnet 4.6 Vertex for Code Review Flow in GitLab 19.1.
- [Separate model selection](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876) from GitLab Duo Code Review introduced for Code Review Flow in GitLab 19.1, using the **Agentic Code Review** setting.
- GPT-5.2 and GPT-5.3 Codex [added](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5652) as selectable models for Code Review Flow in GitLab 19.1.
- Ability to restrict GitLab Duo Agentic Chat to specific models [added](https://gitlab.com/groups/gitlab-org/-/work_items/22028) in GitLab 19.1.

{{< /history >}}

You can select a model to be the default model for a feature in a top-level group.
The model that you select applies to that feature for all child groups and projects.

Prerequisites:

- You have the Owner role for the group.
- The group that you select models for is a top-level group.
- In GitLab 18.3 or later, if you belong to multiple GitLab Duo namespaces, you must [assign a default namespace](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

### Select a model for Agentic Chat

To select a model for Agentic Chat:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Configure features**.
1. Go to the **GitLab Duo Agentic Chat** section.
1. Select a model from the dropdown list to set as the default model.
1. Optional. To restrict what other models users can select for Agentic Chat:

   1. Under **Available models**, select **Configure**.
   1. In the **Available models: Agentic Chat** dialog, select the
      **Restrict to specific models** checkbox.
   1. Select the models that you want Agentic Chat to be able to use.
   1. Select **Save**.

   > [!note]
   > If you do not restrict Agentic Chat to specific models, users can choose from
   > all GitLab-managed models.

### Select a model for a non-Agentic Chat feature

To select a model for a non-Agentic Chat feature:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Configure features**.
1. Go to the **GitLab Duo Agent Platform** section.
1. Select a model from the dropdown list to set as the default model.
1. Optional. To apply the model to all features in the section, select **Apply to all**.

To specify a model for the GitLab Duo CLI, see [select a model](../gitlab_duo_cli/_index.md#select-a-model).

### Selecting the right model

For many use cases, starting with a faster, more cost-effective model like
Claude Haiku 4.5 or GPT-5.4 Mini can be the optimal approach.
For this approach:

1. Select Claude Haiku 4.5 or GPT-5.4 Mini.
1. Test your use case thoroughly.
1. Evaluate if performance meets your requirements.
1. Upgrade only if necessary for specific capability gaps.

You can use this approach for the following:

- Exploratory or high-volume tasks
- Applications with strict latency requirements
- Cost-sensitive implementations

## Troubleshooting

When selecting models other than the default, you might encounter the following issues.

### Model is not available

If you are using the default GitLab model for a GitLab Duo AI-native feature, GitLab might change the default model without notifying the user to maintain optimal performance and reliability.

If you have selected a specific model for a GitLab Duo AI-native feature, and that model is not available, there is no automatic fallback. The feature that uses this model is unavailable.

### No default GitLab Duo namespace

When using a GitLab Duo feature with a selected model, you might get an error that indicates that you need to set a default GitLab Duo namespace.

This issue occurs when you belong to multiple GitLab Duo namespaces or work on a project locally
that does not have a GitLab remote configured.

To resolve this, [set a default GitLab Duo namespace](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

### Model selection for Agentic Chat in IDEs does not work

When selecting a model for Agentic Chat in your IDE, you might find that model
selection does not work.

To resolve this:

1. Check that the connection type for your IDE is set to WebSocket.
1. Ask your network administrator to make sure
   [WebSocket traffic to your GitLab instance is allowed](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance).
