---
stage: none
group: Tutorials
info: For assistance with this tutorial, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Move your personal project to a group **(FREE SAAS)**

This tutorial will show you how to move a personal project to a group.

## Why is a group important?

In GitLab, you use [groups](../user/group/index.md)
to manage one or more related projects at the same time.
A group gives you some great benefits. For example, you can:

- Manage permissions for your projects.
- View all of the issues and merge requests for the projects in the group.
- View all unique users in your namespace, across all projects.
- Manage usage quotas.
- Start a trial or upgrade to a paid tier. This option is important if you're
  impacted by the [changes to user limits](https://about.gitlab.com/blog/2022/03/24/efficient-free-tier/),
  and need more users.

However, if you're working in a [personal project](../user/project/working_with_projects.md#view-personal-projects),
you can't use these features. Personal projects are created under your
[personal namespace](../user/namespace/index.md). They're not part of a group,
so you can't get any of the benefits and features of a group.

But don't worry! You can move your existing personal project to a group.
The next steps show you how.

## Steps

Here's an overview of what we're going to do:

1. [Create a group](#create-a-group).
1. [Move your project to a group](#move-your-project-to-a-group).
1. [Work with your group](#work-with-your-group).

### Create a group

To begin, make sure you have a suitable group to move your project to.
The group must allow the creation of projects, and you must have at least the
Maintainer role for the group.

If you don't have a group, create one:

1. On the top bar, select **Main menu > Groups > View all groups**.
1. On the right of the page, select **New group**.
1. In **Group name**, enter a name for the group.
1. In **Group URL**, enter a path for the group, which is used as the namespace.
1. Choose the [visibility level](../user/public_access.md).
1. Optional. Fill in information to personalize your experience.
1. Select **Create group**.

### Move your project to a group

Before you move your project to a group:

- You must have the Owner role for the project.
- Remove any [container images](../user/packages/container_registry/index.md#limitations)
  and [NPM packages](../user/packages/npm_registry/index.md#limitations).

Now you're ready to move your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Under **Transfer project**, choose the group to transfer the project to.
1. Select **Transfer project**.
1. Enter the project's name and select **Confirm**.

You are redirected to the project's new page.
If you have more than one personal project, you can repeat these steps for each
project.

NOTE:
For more information about these migration steps,
see [Transferring your project into another namespace](../user/project/settings/index.md#transfer-a-project-to-another-namespace).
A migration might result in follow-up work to update the project path in
your related resources and tools, such as websites and package managers.

### Work with your group

You can now view your project in your group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. Look for your project under **Subgroups and projects**.

Start enjoying the benefits of a group! For example, as the group Owner, you can
quickly view all unique users in your namespace:

1. In your group, select **Settings > Usage Quotas**.
1. The **Seats** tab displays all users across all projects in your group.
