---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Control GitLab Duo (Classic) availability
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Settings to turn AI features on and off introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.
- [Settings to turn AI features on and off added to the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) in GitLab 16.11.

{{< /history >}}

GitLab Duo (Classic) is on by default.
GitLab Duo includes a [set of features](feature_summary.md).

You can turn GitLab Duo on or off:

- On GitLab.com: For top-level groups, other groups or subgroups, and projects.
- On GitLab Self-Managed: For instances, groups or subgroups, and projects.

## Turn GitLab Duo on or off

### On GitLab.com

#### For a top-level group

Prerequisites:

- The Owner role for the top-level group.

To change GitLab Duo availability for a top-level group:

1. On the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a group or subgroup

Prerequisites:

- The Owner role for the group or subgroup.

To change GitLab Duo availability for a group or subgroup:

1. On the top bar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a project

Prerequisites:

- The Owner or Maintainer role for the project.

To change GitLab Duo availability for a project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn the **Use AI-native features in this project** toggle on or off.
1. Select **Save changes**.

### On GitLab Self-Managed

#### For an instance

Prerequisites:

- Administrator access.

To change GitLab Duo availability for an instance:

1. In the upper-right corner, select **Admin**.
1. On the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

#### For a group or subgroup

Prerequisites:

- The Owner role for the group or subgroup.

To change GitLab Duo availability for a group or subgroup:

1. On the top bar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a project

Prerequisites:

- The Owner or Maintainer role for the project.

To change GitLab Duo availability for a project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn the **Use AI-native features in this project** toggle on or off.
1. Select **Save changes**.

### For earlier GitLab versions

For information on how to turn GitLab Duo on or off in earlier GitLab versions, see
[control GitLab Duo (Classic) availability for earlier GitLab versions](turn_on_off_earlier.md).

## Turn GitLab Duo Core on or off

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/538857) in GitLab 18.0.
- GitLab Duo availability settings and group, subgroup, and project controls [added](https://gitlab.com/gitlab-org/gitlab/-/issues/551895) in GitLab 18.2.
- GitLab Duo Chat (Classic) [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721) to GitLab Duo Core in GitLab 18.3.

{{< /history >}}

GitLab Duo Core is included with Premium and Ultimate subscriptions.

- If you are an existing customer from GitLab 17.11 or earlier, you must turn on features for GitLab Duo Core.
- If you are a new customer in GitLab 18.0 or later, GitLab Duo Core is automatically turned on and no further action is needed.

If you were an existing customer with a Premium or Ultimate subscription before May 15, 2025,
when you upgrade to GitLab 18.0 or later, to use GitLab Duo Core, you must turn it on.

### On GitLab.com

Prerequisites:

- The Owner role for the top-level group.

To change GitLab Duo Core availability for a top-level group:

1. On the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Under **GitLab Duo Core**, select or clear the **Turn on features for GitLab Duo Core** checkbox.
   If you selected **Always off** for GitLab Duo availability, you cannot access
   this setting.
1. Select **Save changes**.

It might take up to 10 minutes for the change to take effect.

### On GitLab Self-Managed

Prerequisites:

- Administrator access.

To change GitLab Duo Core availability for an instance:

1. In the upper-right corner, select **Admin**.
1. On the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Under **GitLab Duo Core**, select or clear the **Turn on features for GitLab Duo Core** checkbox.
   If you selected **Always off** for GitLab Duo availability, you cannot access
   this setting.
1. Select **Save changes**.

## Turn on beta and experimental features

GitLab Duo features that are experimental and beta are turned off by default.
These features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

### On GitLab.com

Prerequisites:

- The Owner role for the top-level group.

To turn on GitLab Duo experiment and beta features for a top-level group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Feature preview**, select **Turn on experiment and beta GitLab Duo features**.
1. Select **Save changes**.

This setting [cascades to all projects](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

### On GitLab Self-Managed

{{< tabs >}}

{{< tab title="In 17.4 and later" >}}

In GitLab 17.4 and later, follow these instructions to turn on GitLab Duo
experiment and beta features for your GitLab Self-Managed instance.

Prerequisites:

- Administrator access.

To turn on GitLab Duo experiment and beta features for an instance:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **GitLab Duo**.
1. Expand **Change configuration**.
1. Under **Feature preview**, select **Use experiment and beta GitLab Duo features**.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

Prerequisites:

- Administrator access.
- [Network connectivity](../../administration/gitlab_duo/configure/gitlab_self_managed.md) enabled.
- [Silent Mode](../../administration/silent_mode/_index.md) turned off.

To turn on GitLab Duo experiment and beta features for an instance:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **GitLab Duo**.
1. Expand **Change configuration**.
1. Under **Feature preview**, select **Use experiment and beta GitLab Duo features**.
1. Select **Save changes**.
1. For GitLab Duo Chat to work immediately,
   [manually synchronize your subscription](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data).

   If you do not manually synchronize your subscription, it might take up to 24
   hours to activate GitLab Duo Chat on your instance.

{{< /tab >}}

{{< /tabs >}}
