---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

If you do not want to use the default model for each feature, or have specific requirements, you can choose from an array of other available supported models.

If you select a specific model for a feature, the feature uses that model until you select another.

## Select a model for the instance

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19144) in GitLab 18.4 with a [flag](../../administration/feature_flags/_index.md) named `instance_level_model_selection`. Enabled by default.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208017) to GitLab Dedicated in GitLab 18.5.
- Feature flag `instance_level_model_selection` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209698) in GitLab 18.6.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210969) to include GitLab Duo Core and Pro in GitLab 18.6.

{{< /history >}}

You can select a model for a feature that applies to the entire instance. If you don't select a specific model,
all GitLab Duo features use the default GitLab model.

Prerequisites:

- You must be an administrator.

To select a model for a feature:

1. In the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md), in the upper-right corner, select **Admin**.
1. Select **GitLab Duo**.
1. On **Configure AI features**, select **Configure models for GitLab Duo**. If **Configure AI features** is not displayed, verify that the GitLab Duo Enterprise add-on is configured for your instance.
1. For the feature you want to configure, select a model from the dropdown list.
1. Optional. To apply the model to all features in the section, select **Apply to all**.
