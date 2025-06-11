---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure large language models for GitLab Duo features.
title: GitLab Duo Model Selection
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Add-on: GitLab Duo Core, Pro or Enterprise
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17570) for top-level groups in GitLab 18.1 with a [flag](../../administration/feature_flags.md) named `ai_model_switching`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

On GitLab.com, you can select specific large language models (LLMs) to use with the GitLab Duo AI-native features to meet your performance and compliance requirements.

If you do not select a specific LLM, the AI-native features use the GitLab-selected **GitLab Default** LLM. You should use this LLM if you do not have unique requirements.

{{< alert type="note" >}}

To maintain optimal performance, GitLab might change the default LLM without notifying the user.

{{< /alert >}}

## Prerequisites

- The group that you want to select LLMs for must:
  - Be a [top-level group](../group/_index.md#group-hierarchy) on GitLab.com.
  - Have GitLab Duo Core, Pro, or Enterprise enabled.
- You must have the Owner role for the group.

## Select an LLM for a feature

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > GitLab Duo**.

   If you do not see **GitLab Duo**, ensure you have GitLab Duo Core, Pro or Enterprise enabled for the group.
1. Select **Configure features**.
1. For the feature you want to configure, select an LLM from the dropdown list.

![Configure Model Selections](img/configure_model_selections_v18_1.png)
