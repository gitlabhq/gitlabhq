---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Control GitLab Duo availability
---

GitLab Duo availability depends on your subscription add-on:

- [GitLab Duo Core](../../subscriptions/subscription-add-ons.md#gitlab-duo-core), or
- [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md#gitlab-duo-pro-and-enterprise).

Depending on your add-on, you can turn GitLab Duo on and off for a group, project, or instance.

## Change GitLab Duo Core availability

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/538857) in GitLab 18.0.

{{< /history >}}

If you have the GitLab Duo Core add-on, which is included with Premium and Ultimate subscriptions,
GitLab Duo Chat and Code Suggestions are available in your IDEs, and are turned on by default.

If you were an existing user with a Premium or Ultimate subscription before May 15, 2025,
Chat and Code Suggestions in your IDEs are turned off by default. To turn on these
features:

1. Upgrade to GitLab 18.0 or later.
1. Turn on the IDE features for your group or instance.

It may take up to 10 minutes for the change to take effect.

### For a group

On GitLab.com, you can turn GitLab Duo Core on or off for a top-level group, but not for a subgroup or project.

Prerequisites:

- You must have the Owner role for the top-level group.

To turn GitLab Duo Core on or off for a top-level group on GitLab.com:

1. On the left sidebar, select **Search or go to** and find your top-level group.
1. Select **Settings > GitLab Duo**.
1. Select **Change configuration**.
1. Below **GitLab Duo Core**, select or clear the **Turn on IDE features** checkbox.
1. Select **Save changes**.

It may take up to 10 minutes for the change to take effect.

### For an instance

On GitLab Self-Managed, you can turn GitLab Duo Core on or off for an instance.

Prerequisites:

- You must be an administrator.

To turn GitLab Duo Core on or off for an instance:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **GitLab Duo**.
1. Select **Change configuration**.
1. Below **GitLab Duo Core**, select or clear the **Turn on IDE features** checkbox.
1. Select **Save changes**.

## Change GitLab Duo Pro and Enterprise availability

{{< history >}}

- [Settings to turn AI features on and off introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.
- [Settings to turn AI features on and off added to the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) in GitLab 16.11.

{{< /history >}}

For GitLab Duo Pro or Enterprise, GitLab Duo is turned on by default.
For some generally available features, like Code Suggestions,
[you must also assign seats](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)
to the users you want to have access.

You can turn GitLab Duo on or off for a group, project, or instance.

When GitLab Duo is turned off for a group, project, or instance:

- GitLab Duo features that access resources, like code, issues, and vulnerabilities, are not available.
- Code Suggestions is not available.
- GitLab Duo Chat is not available.

### For a group or subgroup

{{< tabs >}}

{{< tab title="In 17.8 and later" >}}

In GitLab 17.8 and later, follow these instructions to turn GitLab Duo on or off
for a group, including its subgroups and projects.

Prerequisites:

- You must have the Owner role for the group.

To turn GitLab Duo on or off for a group or subgroup:

1. On the left sidebar, select **Search or go to** and find your group or subgroup.
1. Go to the settings, based on your deployment type and group level:
   - For GitLab.com top-level groups: Select **Settings > GitLab Duo** and select **Change configuration**.
   - For GitLab.com subgroups: Select **Settings > General** and expand **GitLab Duo features**.
   - For GitLab Self-Managed (all groups and subgroups): Select **Settings > General** and expand **GitLab Duo features**.
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
1. Select **Settings > GitLab Duo**.
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
1. Select **Settings > GitLab Duo**.
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
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Select or clear the **Use GitLab Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade the setting to
   all subgroups.

   ![Cascading setting](img/disable_duo_features_v17_1.png)

{{< /tab >}}

{{< /tabs >}}

### For a project

{{< tabs >}}

{{< tab title="In 17.4 and later" >}}

In GitLab 17.4 and later, follow these instructions to turn GitLab Duo on or off for a project.

Prerequisites:

- You must have the Owner role for the project.

To turn GitLab Duo on or off for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
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

### For an instance

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="In 17.7 and later" >}}

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
1. Select **Settings > General**.
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
1. Select **Settings > General**.
1. Expand **AI-powered features**.
1. Select or clear the **Use Duo features** checkbox.
1. Optional. Select the **Enforce for all subgroups** checkbox to cascade
   the setting to all groups in the instance.

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/441532) to allow administrators
to override the setting for specific groups or projects.

{{< /alert >}}

## Turn on beta and experimental features

GitLab Duo features that are experimental and beta are turned off by default.
These features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

### On GitLab.com

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="In 17.4 and later" >}}

In GitLab 17.4 and later, follow these instructions to
turn on GitLab Duo experimental and beta features for your group on GitLab.com.

{{< alert type="note" >}}

In GitLab 17.4 to 17.6, you can change this setting for top-level groups only. (Subgroups do not have the required settings.)
In GitLab 17.7 and later, the settings are available for all groups.

{{< /alert >}}

Prerequisites:

- You must have the Owner role for the top-level group.

To turn on GitLab Duo experiment and beta features for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > GitLab Duo**.
1. Under **GitLab Duo** section, select **Change configuration**.
1. Under **Feature preview**, select **Turn on experiment and beta GitLab Duo features**.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

In GitLab 17.3 and earlier, follow these instructions to
turn on GitLab Duo experimental and beta features for your group on GitLab.com.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **GitLab Duo experiment and beta features**, select the **Use experiment and beta GitLab Duo features** checkbox.
1. Select **Save changes**.

{{< /tab >}}

{{< /tabs >}}

This setting [cascades to all projects](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

### On GitLab Self-Managed

{{< tabs >}}

{{< tab title="In 17.4 and later" >}}

In GitLab 17.4 and later, follow these instructions to turn on GitLab Duo
experiment and beta features for your GitLab Self-Managed instance.

{{< alert type="note" >}}

In GitLab 17.4 to 17.6, the GitLab Duo settings page is available for Self-Managed instances.
Beginning with GitLab 17.7, the settings page includes more configuration options.

{{< /alert >}}

Prerequisites:

- You must be an administrator.

To turn on GitLab Duo experiment and beta features for an instance:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Settings > GitLab Duo**.
1. Expand **Change configuration**.
1. Under **Feature Preview**, select **Use experiment and beta GitLab Duo features**.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

To enable GitLab Duo beta and experimental features for GitLab versions
where GitLab Duo Chat is not yet generally available, see the
[GitLab Duo Chat documentation](../gitlab_duo_chat/turn_on_off.md#for-gitlab-self-managed).

{{< /tab >}}

{{< /tabs >}}
