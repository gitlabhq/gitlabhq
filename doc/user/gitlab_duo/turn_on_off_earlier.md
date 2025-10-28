---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo availability - earlier versions
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Pro or Enterprise
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Settings to turn AI features on and off introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.
- [Settings to turn AI features on and off added to the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) in GitLab 16.11.

{{< /history >}}

For GitLab Duo Pro or Enterprise, you can turn GitLab Duo on or off for a group, project, or instance.

{{< alert type="note" >}}

This information applies to GitLab 18.1 and earlier. For GitLab 18.2 and later, view [the latest documentation](turn_on_off.md).

{{< /alert >}}

When GitLab Duo is turned off for a group, project, or instance:

- GitLab Duo features that access resources, like code, issues, and vulnerabilities, are not available.
- Code Suggestions is not available.
- GitLab Duo Chat is not available.

## For a group or subgroup

{{< tabs >}}

{{< tab title="In 17.8 to 18.1" >}}

In GitLab 17.8 and later, follow these instructions to turn GitLab Duo on or off
for a group, including its subgroups and projects.

Prerequisites:

- You must have the Owner role for the group.

To turn GitLab Duo on or off for a group or subgroup:

1. On the left sidebar, select **Search or go to** and find your group or subgroup.
1. Go to the settings, based on your deployment type and group level:
   - For GitLab.com top-level groups: Select **Settings** > **GitLab Duo** and select **Change configuration**.
   - For GitLab.com subgroups: Select **Settings** > **General** and expand **GitLab Duo features**.
   - For GitLab Self-Managed (all groups and subgroups): Select **Settings** > **General** and expand **GitLab Duo features**.
1. Choose an option.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.7" >}}

In GitLab 17.7, follow these instructions to turn GitLab Duo on or off
for a group, including its subgroups and projects.

{{< alert type="note" >}}

In GitLab 17.7:

- For GitLab.com, the GitLab Duo settings page is only available for top-level groups, not for subgroups.

- For GitLab Self-Managed, the GitLab Duo settings page is not available for groups or subgroups.

{{< /alert >}}

Prerequisites:

- You must have the Owner role for the group.

To turn GitLab Duo on or off for a top-level group:

1. On the left sidebar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Choose an option.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.4 to 17.6" >}}

In GitLab 17.4 to 17.6, follow these instructions to turn GitLab Duo on or off
for a group and its subgroups and projects.

{{< alert type="note" >}}

In GitLab 17.4 to 17.6:

- For GitLab.com, the GitLab Duo settings page is only available for top-level groups, not for subgroups.

- For GitLab Self-Managed, the GitLab Duo settings page is not available for groups or subgroups.

{{< /alert >}}

Prerequisites:

- You must have the Owner role for the group.

To turn GitLab Duo on or off for a top-level group:

1. On the left sidebar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Choose an option.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

In GitLab 17.3 and earlier, follow these instructions to turn GitLab Duo on or off for a group
and its subgroups and projects.

Prerequisites:

- You must have the Owner role for the group.

To turn GitLab Duo on or off for a group or subgroup:

1. On the left sidebar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Select or clear the **Use GitLab Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade the setting to
   all subgroups.

   ![Cascading setting](img/disable_duo_features_v17_1.png)

{{< /tab >}}

{{< /tabs >}}

## For a project

{{< tabs >}}

{{< tab title="In 17.4 to 18.1" >}}

In GitLab 17.4 and later, follow these instructions to turn GitLab Duo on or off for a project.

Prerequisites:

- You must have the Owner or Maintainer role for the project.

To turn GitLab Duo on or off for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Under **GitLab Duo**, turn the toggle on or off.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

In GitLab 17.3 and earlier, follow these instructions to turn GitLab Duo on or off for a project.

1. Use the GitLab GraphQL API
   [`projectSettingsUpdate`](../../api/graphql/reference/_index.md#mutationprojectsettingsupdate)
   mutation.
1. Set the
   [`duo_features_enabled`](../../api/graphql/getting_started.md#update-project-settings)
   setting to `true` or `false`.

{{< /tab >}}

{{< /tabs >}}

## For an instance

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="In 17.7 to 18.1" >}}

In GitLab 17.7 and later, follow these instructions to turn GitLab Duo on or off for an instance.

Prerequisites:

- You must be an administrator.

To turn GitLab Duo on or off for an instance:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **GitLab Duo**.
1. Select **Change configuration**.
1. Choose an option.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.4 to 17.6" >}}

In GitLab 17.4 to 17.6, follow these instructions to turn GitLab Duo on or off for the instance.

Prerequisites:

- You must be an administrator.

To turn GitLab Duo on or off for an instance:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Choose an option.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

In GitLab 17.3 and earlier, follow these instructions to turn GitLab Duo on or off for an instance.

Prerequisites:

- You must be an administrator.

To turn GitLab Duo on or off for an instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **AI-powered features**.
1. Select or clear the **Use Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade
   the setting to all groups in the instance.

{{< /tab >}}

{{< /tabs >}}
