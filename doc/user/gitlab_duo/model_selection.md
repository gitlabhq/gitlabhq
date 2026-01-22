---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure large language models for GitLab Duo features.
title: GitLab Duo (Classic) model selection
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro or Enterprise
- Offering: GitLab.com

{{< /details >}}

Every GitLab Duo feature has a default large language model, chosen by GitLab.

GitLab can update this default model to optimize feature performance. Therefore, a feature's model might change without you taking any action.

If you don't want to use the default model for each feature, or have specific requirements, you can choose from an array of other available supported models.

If you select a specific model for a feature, the feature uses that model until you select another.

## Select a model for a feature

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17570) for top-level groups in GitLab 18.1 with a [flag](../../administration/feature_flags/_index.md) named `ai_model_switching`. Disabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) to beta in GitLab 18.4.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) in GitLab 18.4.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/18818) in GitLab 18.5. Feature flag `ai_model_switching` enabled.
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
