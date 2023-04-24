---
stage: Data Stores
group: Tenant Scale
info: For assistance with this tutorial, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Tutorial: Convert a personal namespace into a group **(FREE SAAS)**

If you've started out on GitLab with a personal [namespace](../../user/namespace/index.md), but now find
that you've outgrown its capabilities and its limitations hinder the collaboration on your projects,
you might want to switch to a group namespace instead.
A group namespace allows you to create multiple subgroups, and manage their members and permissions.

You don't have to start from scratch - you can create a new group
and move your existing projects to the group to get the added benefits.
To find out how, see [Tutorial: Move your personal project to a group](../move_personal_project_to_group/index.md).

But you can go one step further and convert your personal namespace into a group namespace,
so you get to keep the existing username and URL. For example, if your username is `alex`,
you can continue using the `https://gitlab.example.com/alex` URL for your group.

This tutorial shows you how to convert your personal namespace into a group namespace
using the following steps:

1. [Create a group](#create-a-group).
1. [Transfer projects from the personal namespace to the group](#transfer-projects-from-the-personal-namespace-to-the-group).
1. [Rename the original username](#rename-the-original-username).
1. [Rename the new group namespace to the original username](#rename-the-new-group-namespace-to-the-original-username).

For example, if your username for a personal namespace is `alex`, first create a group namespace named `alex-group`.
Then, move all projects from the `alex` to the `alex-group` namespace. Finally,
rename the `alex` namespace to `alex-user`, and `alex-group` namespace to the now available `alex` username.

## Create a group

1. On the top bar, select **Main menu > Groups > View all groups**.
1. On the right of the page, select **New group**.
1. In **Group name**, enter a name for the group.
1. In **Group URL**, enter a path for the group, which is used as the namespace.
   Don't worry about the actual path, this is only temporary. You'll change this URL to the username of the personal namespace in the [final step](#rename-the-new-group-namespace-to-the-original-username).
1. Choose the [visibility level](../../user/public_access.md).
1. Optional. Fill in information to personalize your experience.
1. Select **Create group**.

## Transfer projects from the personal namespace to the group

Next, you must transfer your projects from the personal namespace to the new group.
You can transfer only one project at a time, so if you want to transfer multiple projects,
you must perform the steps below for each project.

Before you start the transfer process, make sure you:

- Have the Owner role for the project.
- Remove [container images](../../user/packages/container_registry/index.md#move-or-rename-container-registry-repositories).
  You can't transfer a project that contains container images.
- Remove npm packages. You can't update the root namespace of a project that contains npm packages.

To transfer a project to a group:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Under **Transfer project**, choose the group to transfer the project to.
1. Select **Transfer project**.
1. Enter the project's name and select **Confirm**.

## Rename the original username

Next, rename the original username of the personal namespace, so that the username becomes available for the new group namespace.
You can keep on using the personal namespace for other personal projects, or [delete that user account](../../user/profile/account/delete_account.md)

From the moment you rename the personal namespace, the username becomes available, so it's possible that someone else registers an account with it. To avoid this, you should [rename the new group](#rename-the-new-group-namespace-to-the-original-username) as soon as possible.

To [change a user's username](../../user/profile/index.md#change-your-username):

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Change username** section, enter a new username as the path.
1. Select **Update username**.

## Rename the new group namespace to the original username

Finally, rename the new group's URL to the username of the original personal namespace.

To [change your group path](../../user/group/manage.md#change-a-groups-path) (group URL):

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General page**.
1. Expand the **Advanced** section.
1. Under **Change group URL**, enter the user's original username.
1. Select **Change group URL**.

That's it! You have now converted a personal namespace into a group, which opens up new possibilities of
working on projects and collaborating with more members.
