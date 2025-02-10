---
stage: Tenant Scale
group: Organizations
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Move your personal project to a group'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

If you created a project under a [personal namespace](../../user/namespace/_index.md),
you can perform common tasks, like managing issues, merge requests,
source control, and CI/CD.

However, at some point you might outgrow your personal project and
want to move your project to a group namespace instead. With a group namespace, you can:

- Give a group of users access to your project, rather than adding users one-by-one.
- View all issues and merge requests for all projects in the group.
- View all unique users in the group namespace, across all projects.
- Manage usage quotas.
- Start a trial or upgrade to a paid subscription tier. This option is important if you're
  impacted by the [changes to user limits](https://about.gitlab.com/blog/2022/03/24/efficient-free-tier/),
  and need more users.

This tutorial shows you how to move your project from a personal namespace
to a group namespace.

## Steps

Here's an overview of the steps:

1. [Create a group](#create-a-group).
1. [Move your project to a group](#move-your-project-to-a-group).
1. [Work with your group](#work-with-your-group).

### Create a group

To begin, make sure you have a suitable group to move your project to.
The group must allow the creation of projects, and you must have at least the
Maintainer role for the group.

If you don't have a group, create one:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New group**.
1. In **Group name**, enter a name for the group.
1. In **Group URL**, enter a path for the group, which is used as the namespace.
1. Choose the [visibility level](../../user/public_access.md).
1. Optional. Fill in information to personalize your experience.
1. Select **Create group**.

### Move your project to a group

Before you move your project to a group:

- You must have the Owner role for the project.
- Remove any [container images](../../user/packages/container_registry/_index.md#move-or-rename-container-registry-repositories)
- Remove any npm packages. If you transfer a project to a different root namespace, the project must not contain any npm packages. When you update the path of a user or group, or transfer a subgroup or project, you must remove any npm packages first. You cannot update the root namespace of a project with npm packages. Make sure you update your .npmrc files to follow the naming convention and run npm publish if necessary.

Now you're ready to move your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Advanced**.
1. Under **Transfer project**, choose the group to transfer the project to.
1. Select **Transfer project**.
1. Enter the project's name and select **Confirm**.

You are redirected to the project's new page.
If you have more than one personal project, you can repeat these steps for each
project.

NOTE:
For more information about these migration steps,
see [Transferring your project into another namespace](../../user/project/settings/migrate_projects.md#transfer-a-project-to-another-namespace).
A migration might result in follow-up work to update the project path in
your related resources and tools, such as websites and package managers.

### Work with your group

You can now view your project in your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Look for your project under **Subgroups and projects**.

Start enjoying the benefits of a group! For example, as the group Owner, you can
quickly view all unique users in your namespace:

1. In your group, select **Settings > Usage Quotas**.
1. The **Seats** tab displays all users across all projects in your group.
