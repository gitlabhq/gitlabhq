---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Control GitLab Duo availability
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Settings to turn AI features on and off introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.
- [Settings to turn AI features on and off added to the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) in GitLab 16.11.
- [Settings to turn flows on and off added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203733) in GitLab 18.4.

{{< /history >}}

GitLab Duo is on by default when you [have a subscription](../../subscriptions/subscription-add-ons.md).

You can turn GitLab Duo on or off:

- On GitLab.com: For top-level groups, other groups or subgroups, and projects.
- On GitLab Self-Managed: For instances, groups or subgroups, and projects.

You can also turn GitLab Duo Core (a subset of GitLab Duo features) on or off.

## Turn GitLab Duo Core on or off

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/538857) in GitLab 18.0.
- GitLab availability settings, and group, subgroup, and project controls [added](https://gitlab.com/gitlab-org/gitlab/-/issues/551895) in GitLab 18.2.
- GitLab Duo Chat (Classic) in the UI [added to Core](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721) in GitLab 18.3.

{{< /history >}}

[GitLab Duo Core](feature_summary.md) is included with Premium and Ultimate subscriptions.

- If you are an existing customer from GitLab 17.11 or earlier, you must turn on Web or IDE features to start using GitLab Duo Core.
- If you are a new customer in GitLab 18.0 or later, GitLab Core is automatically turned on and no further action is needed.

If you were an existing customer with a Premium or Ultimate subscription before May 15, 2025,
when you upgrade to GitLab 18.0 or later, to use GitLab Duo Core, you must turn it on.

### On GitLab.com

On GitLab.com, you can change availability for GitLab Duo Core for your top-level group (namespace).

Prerequisites:

- You must have the Owner role for the top-level group.

To change GitLab Duo Core availability:

1. On the left sidebar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability in this namespace**, select an option.
1. Under **GitLab Duo Core**, select or clear the **Turn on Web and IDE features** checkbox.
   If you selected **Always off** for GitLab Duo availability, you cannot access
   this setting.
1. Select **Save changes**.

It might take up to 10 minutes for the change to take effect.

### On GitLab Self-Managed

On GitLab Self-Managed, you can change availability for GitLab Duo Core for your instance.

Prerequisites:

- You must be an administrator.

To change GitLab Duo Core availability:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability in this instance**, select an option.
1. Under **GitLab Duo Core**, select or clear the **Turn on Web and IDE features** checkbox.
   If you selected **Always off** for GitLab Duo availability, you cannot access
   this setting.
1. Select **Save changes**.

## Turn GitLab Duo on or off

GitLab Duo is on by default when you [have a subscription](../../subscriptions/subscription-add-ons.md).
You can choose to change its availability for different groups and projects.

### On GitLab.com

On GitLab.com, you can control GitLab Duo availability for the top-level group,
other groups, subgroups, and projects.

#### For a top-level group

Prerequisites:

- You must have the Owner role for the group.

To change GitLab Duo availability for the top-level group:

1. On the left sidebar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability in this namespace**, select an option.
1. Use the **Allow flow execution** toggle to control whether agents can run in the GitLab UI.
   When turned on, agents execute in CI/CD pipelines and consume compute minutes.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a group or subgroup

Prerequisites:

- You must have the Owner role for the group.

To change GitLab Duo availability for a group or subgroup:

1. On the left sidebar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo availability in this group**, select an option.
1. Use the **Allow flow execution** toggle to control whether agents can run in the GitLab UI.
   When turned on, agents execute in CI/CD pipelines and consume compute minutes.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a project

Prerequisites:

- You must have the Owner or Maintainer role for the project.

To change GitLab Duo availability for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn the **Use AI-native features in this project** toggle on or off.
1. Use the **Allow flow execution** toggle to control whether agents can run in the GitLab UI.
   When turned on, agents execute in CI/CD pipelines and consume compute minutes.
1. Select **Save changes**.

### On GitLab Self-Managed

On GitLab Self-Managed, you can control GitLab Duo availability for the instance,
groups, subgroups, or projects.

#### For an instance

Prerequisites:

- You must be an administrator.

To change GitLab Duo availability for the instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability in this instance**, select an option.
1. Use the **Allow flow execution** toggle to control whether agents can run in the GitLab UI.
   When turned on, agents execute in CI/CD pipelines and consume compute minutes.
1. Select **Save changes**.

GitLab Duo availability changes for the entire instance.

#### For a group or subgroup

Prerequisites:

- You must have the Owner role for the group or subgroup.

To change GitLab Duo availability for a group or subgroup:

1. On the left sidebar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo availability in this group**, select an option.
1. Use the **Allow flow execution** toggle to control whether agents can run in the GitLab UI.
   When turned on, agents execute in CI/CD pipelines and consume compute minutes.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a project

Prerequisites:

- You must have the Owner or Maintainer role for the project.

To change GitLab Duo availability for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn the **Use AI-native features in this project** toggle on or off.
1. Use the **Allow flow execution** toggle to control whether agents can run in the GitLab UI.
   When turned on, agents execute in CI/CD pipelines and consume compute minutes.
1. Select **Save changes**.

GitLab Duo availability changes for the project.

### For earlier GitLab versions

For information on how to turn GitLab Duo on of off in earlier GitLab versions,
see [Control GitLab Duo availability for earlier GitLab versions](turn_on_off_earlier.md).

## Turn on beta and experimental features

GitLab Duo features that are experimental and beta are turned off by default.
These features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

### On GitLab.com

Prerequisites:

- You must have the Owner role for the top-level group.

To turn on GitLab Duo experiment and beta features for a top-level group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Under **GitLab Duo** section, select **Change configuration**.
1. Under **Feature preview**, select **Turn on experiment and beta GitLab Duo features**.
1. Select **Save changes**.

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
1. Select **Settings** > **GitLab Duo**.
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
