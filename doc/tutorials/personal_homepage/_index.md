---
stage: Growth
group: Engagement
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Use the personal homepage'
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/546151) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `personal_homepage`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/554048) in GitLab 18.4 for a subset of users.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/epics/17932) in GitLab 18.5.

{{< /history >}}

<!-- vale gitlab_base.FutureTense = NO -->

The personal homepage consolidates all information relevant to you in one place.
You can quickly identify new work items that need your attention, or pick up where you left off.

Follow this tutorial to learn how to find your way around the homepage,
and to get the most out of it.

## Before you begin

Set the [personal homepage](../../user/profile/preferences.md#choose-your-homepage)
as the default homepage in your preferences.

## Access the homepage

You can access your personal homepage from anywhere in GitLab:

- On the left sidebar, at the top, select **Homepage**.
- On the left sidebar, select **Search or go to**, select **Your work**, then select **Home**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.

## Layout of the homepage

Near the top, select your avatar to set your status. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
If you have set a status, your avatar displays a status badge and emoji, and you can hover to view your status text.

Below your avatar, view the number of merge requests and issues that you're involved with. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), these buttons are in the upper-right corner.

The **Items that need your attention** list shows all work items across GitLab that need your input.

The **Follow the latest updates** feed shows your activity across GitLab,
and the activity of specific projects and users you're interested in.

Go to the right side of the homepage to get a list of items you've recently viewed.

## Use the homepage to start your day

Let's go over a few ways you can use the homepage to get started with your
work for the day:

1. Use the filter in the **Items that need your attention** list to view the events that are most important to you.
   For example, to see merge requests that are blocked because of failed pipelines, select **Failed builds** from the filter dropdown list.
1. Near the top of the homepage, select **Merge requests waiting for your review** to view the merge requests that need your review, so you can unblock others.

You can also keep track of what you have been working on, for example:

1. In the **Follow the latest updates** section, use the **Your activity** filter to see your recent work.
   Select the links to go directly to the issue or merge request, and pick up where you left off.
1. Select any of the links in the **Recently viewed** section to get back to items you started working on.

## Stay connected with team activity

If you're collaborating in a project, add a star to the project to make it easier to find in future.
Then, use the homepage to get an overview of what's happening in that project.

To add a star to a project and view its activity on the homepage:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. In the upper-right corner of the page, select **Star** ({{< icon name="star" >}}).
1. On the left sidebar, at the top, select **Homepage**.
1. In the **Follow the latest updates** section, select **Starred projects** from the dropdown list.

To collaborate more effectively with your team, you can follow other GitLab users and see what they're working on:

1. Go to the user's profile in GitLab, for example, `https://gitlab.example.com/username`, and select **Follow**.
   Alternatively, select **Follow** in the small popover that appears when you hover over their name anywhere in GitLab.
1. On the left sidebar, at the top, select **Homepage**.
1. In the **Follow the latest updates** section, select **Followed users** from the dropdown list.

## Related topics

Learn more about the different work items you can view and access from the homepage.

- [To-Do List](../../user/todos.md)
- [Merge requests](../../user/project/merge_requests/_index.md)
- [Issues](../../user/project/issues/_index.md)
