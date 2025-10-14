---
stage: Foundations
group: Design System
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab interface redesign
description: Learn about an upcoming redesign of GitLab user interface.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/18710) in GitLab 18.5 [with flags](../administration/feature_flags/_index.md) named `paneled_view`.
  Disabled by default. This feature is an [experiment](../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

This interface redesign prepares the GitLab UI for AI-native workflows where intelligent agents
work alongside development teams.
This modernized interface centralizes AI interactions in a persistent sidebar, introduces
a panel-based layout that accommodates both traditional development tasks and AI-assisted workflows,
and reduces navigation complexity.

This feature is an [experiment](../policy/development_stages_support.md).
To test this feature on GitLab Self-Managed: Contact your GitLab administrator.

To report a bug, create an issue under [epic 19602](https://gitlab.com/groups/gitlab-org/-/epics/19602).

![Projects page with the new UI.](img/paneled_view_projects_v18_5.png)

## Turn new navigation on or off

Prerequisites:

- Your administrator must have enabled all the related feature flags for your user.
  For specific flags, see the History section at the top of this page.

You can tell that you're using the older navigation if your user avatar is on the left sidebar.

To turn on the new navigation style:

1. On the left sidebar, select your avatar.
1. Turn on the **New UI** toggle.

The page refreshes, and you can start exploring the new GitLab navigation!

To turn off the new navigation style:

1. In the upper-right corner, select your avatar.
1. Turn off the **New UI** toggle.

## What's new

When you turn on the new UI, you get a modern design with more rounded edges and the following changes.

### Search bar moves to the center

The **Search or go to** field is now in the center of the top bar, which makes it more discoverable.

### Top bar buttons move to the right

The following buttons are in the upper-right corner:

- **Create new**
- Your assigned issues
- Your assigned merge requests
- Your to-do items
- **Admin** (administrators only)
- Your avatar and its options

![Top bar buttons with the new UI.](img/paneled_view_top_buttons_v18_5.png)

### GitLab Duo is always accessible

Buttons to access GitLab Duo Chat, sessions, and suggestions are visible in all GitLab views.
They open in a sidebar and can stay open as you move across GitLab.

![GitLab Duo buttons with the new UI](img/paneled_view_duo_sidebar_v18_5.png)

### Improved opening work items in the details panel

You could already open [work items in a drawer](project/issues/managing_issues.md#open-issues-in-a-drawer).
GitLab now uses a details panel that fits in better with the context of your work.

To open the item in the full page view, either:

- On the Issues or Epics page, right-click the item and open it in a new tab.
- Select the item, and from the details panel select its ID (for example, `myproject#123456`).

If there's enough screen space, the details panel opens next to the list or board you open it from.
On smaller screens, the detail panel covers the list or board panel.

![Issue opened in a panel side by side with the Issues panel.](img/paneled_view_issue_drawer_v18_5.png)

![Issue opened in a panel covering part of the Issues panel.](img/paneled_view_issue_drawer_overlap_v18_5.png)

#### Set preference for opening work items in a panel

By default, work items like issues or epics open in the details panel.
If you prefer to turn it off:

1. On the top sidebar, select **Search or go to** and find your project or group.
1. Select **Plan** > **Issues** or **Epics**.
1. At the top of the Issues or Epics page, select **Display options** ({{< icon name="preferences" >}})
   and turn off the **Open items in side panel** toggle.

Your preference is saved and applies across GitLab.
