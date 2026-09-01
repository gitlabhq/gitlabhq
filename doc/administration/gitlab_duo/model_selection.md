---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure large language models for GitLab Duo features.
title: Model selection
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Every GitLab Duo feature has a default large language model (LLM) chosen by GitLab.

GitLab can update this default model to optimize feature performance. Therefore, a feature's model might change without you taking any action.

Model changes come from the GitLab AI Gateway and take effect regardless of your GitLab version, unless otherwise noted.

If you do not want to use the default model for each feature, or have specific requirements, you can choose from an array of other available supported models.

If you select a specific model for a feature, the feature uses that model until you select another.

## Select a model for the instance

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/19144) in GitLab 18.4 with a [flag](../feature_flags/_index.md) named `instance_level_model_selection`. Enabled by default.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208017) to GitLab Dedicated in GitLab 18.5.
- Feature flag `instance_level_model_selection` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209698) in GitLab 18.6.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210969) to include GitLab Duo Core and Pro in GitLab 18.6.

{{< /history >}}

You can select a default model for a feature and that default applies to the
entire instance. If you do not select a specific model, all GitLab Duo features
use the default GitLab model.

> [!note]
> For GitLab Self-Managed instances with an offline license, to change the model for features in the GitLab Duo Agent Platform,
> you must have the [GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md) add-on.

Prerequisites:

- You must be an administrator.

> [!note]
> For GitLab 19.0 or earlier, Code Review Flow and GitLab Duo Code Review share the same model setting.
> Changes you make to the model impact both features.

To select a model for a feature:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Under **Model selection**, select **Manage models**. If **Model selection** is not displayed, verify that the GitLab Duo Enterprise add-on is configured for your instance.
1. For the feature you want to configure, select a model from the dropdown list
   to set as the default model.
1. Optional. To apply the model to all features in the section, select **Apply to all**.

   > [!note]
   > If you select **Default** for all features, each feature uses its own GitLab
   > default model, which might vary between features.

### Select a model for Agentic Chat

{{< history >}}

- Ability to restrict GitLab Duo Agentic Chat to specific models [added](https://gitlab.com/groups/gitlab-org/-/work_items/22028) in GitLab 19.1.

{{< /history >}}

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Under **Model selection**, select **Manage models**.
1. Go to the **GitLab Duo Agentic Chat** section.
1. Select a model from the dropdown list to set as the default model. If you plan
   to restrict access to other models, select a GitLab-managed model as the default.
1. Optional. To restrict what other models users can select for Agentic Chat:

   1. Under **Available models**, select **Configure**.
   1. In the **Available models: Agentic Chat** dialog, select the
      **Restrict to specific models** checkbox.
   1. Select the models that you want Agentic Chat to be able to use.
      To select every model, select the **Select all models** checkbox.
      When every model is selected, select **Clear all models** to clear the selection.

      > [!note]
      > The default model is always available to users and cannot be cleared.
      > To save your changes, you must select at least one model in addition to the default model.

   1. Select **Save**.

   > [!note]
   > To restrict Agentic Chat to specific models, you must select a GitLab-managed
   > model as the default model.
   > If you do not restrict Agentic Chat to specific models, users can choose from
   > all GitLab-managed models.

### Select a model for Code Review Flow

{{< history >}}

- [Separate model setting](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876) from GitLab Duo Code Review introduced for Code Review Flow in GitLab 19.1, using the **Agentic Code Review** setting.

{{< /history >}}

For Code Review Flow, the setting for model selection differs based on your GitLab version.

{{< tabs >}}

{{< tab title="GitLab 19.1 or later" >}}

To select a model for Code Review Flow:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Under **Model selection**, select **Manage models**.
1. Under **GitLab Duo Agent Platform**, find **Agentic Code Review**.
1. Select a model from the dropdown list to set as the default model.

For a list of available models, see [Agent Platform AI models](../../user/duo_agent_platform/model_selection.md#supported-models).

{{< /tab >}}

{{< tab title="GitLab 19.0 or earlier" >}}

Code Review Flow shares a model setting with GitLab Duo Code Review, the non-agentic version of
the feature.
The model you select applies to both features, and you can only choose from the [models available](../../user/gitlab_duo/model_selection.md#gitlab-duo-for-merge-requests)
for the non-agentic feature.

To select a model for Code Review Flow:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Under **Model selection**, select **Manage models**.
1. Under **GitLab Duo for merge requests**, find **Code Review**.
1. Select a model from the dropdown list to set as the default model.

{{< /tab >}}

{{< /tabs >}}
