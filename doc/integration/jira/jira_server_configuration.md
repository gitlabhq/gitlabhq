---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Create a Jira user, group, and permission scheme to authenticate the Jira issues integration in GitLab.
title: 'Tutorial: Create Jira credentials'
---

In this tutorial, you'll set up a dedicated Jira user and grant it the permissions the
Jira issues integration needs. All steps are performed in Jira, not in GitLab.

After you complete this tutorial, use the Jira username and password you create here to
configure the Jira issues integration in GitLab.

To create Jira credentials:

1. [Create a Jira user](#create-a-jira-user).
1. [Create a Jira group for the user](#create-a-jira-group-for-the-user).
1. [Create a permission scheme for the group](#create-a-permission-scheme-for-the-group).
1. [Assign the permission scheme to your projects](#assign-the-permission-scheme-to-your-projects).

## Before you begin

- You must have the **Jira administrators** or **Jira System administrators**
  [global permission](https://confluence.atlassian.com/adminjiraserver/managing-global-permissions-938847142.html).

## Create a Jira user

To create a Jira user:

1. In the upper-right corner, select **Administration** > **User management**.
1. [Create a new user account](https://confluence.atlassian.com/adminjiraserver/create-edit-or-remove-a-user-938847025.html#Create,edit,orremoveauser-CreateusersmanuallyinJira)
   with write access to your Jira projects:

   - In **Email address**, enter a valid email address.
   - In **Username**, enter `gitlab`.
   - In **Password**, enter a password.
     The Jira issues integration does not support SSO such as SAML.

1. Select **Create user**.

You can also use an existing user account, provided the user belongs to a group with the
required permissions.

Now that you've created a user named `gitlab`, it's time to create a group for the user.

## Create a Jira group for the user

To create a Jira group for the user:

1. In the upper-right corner, select **Administration** > **User management**.
1. In the left sidebar, select **Groups**.
1. In the **Add group** section, enter a name for the group (for example, `gitlab-developers`),
   then select **Add group**.
1. To add the `gitlab` user to the `gitlab-developers` group, select **Edit members**.
   The `gitlab-developers` group appears as a selected group.
   <!-- vale gitlab_base.BadPlurals = NO -->
1. In the **Add members to selected group(s)** section, enter `gitlab`.
   <!-- vale gitlab_base.BadPlurals = YES -->
1. Select **Add selected users**.
   The `gitlab` user appears as a group member.

Now that you've added the `gitlab` user to the `gitlab-developers` group,
it's time to create a permission scheme for the group.

## Create a permission scheme for the group

The Jira issues integration needs permission to browse projects, create and edit issues,
and add comments. Grant only the permissions required for these actions.

To create a permission scheme:

1. In the upper-right corner, select **Administration** > **Issues**.
1. In the left sidebar, select **Permission schemes**.
1. Select **Add permission scheme**.
1. In the **Add permission scheme** dialog, complete the fields.
1. Select **Add**.
1. On the **Permission schemes** page, in the **Actions** column, select **Permissions** for the
   new scheme.
1. For each of the following permissions, select **Edit**, grant the permission to the
   `gitlab-developers` group, then select **Grant**:

   - **Browse Projects**
   - **Create Issues**
   - **Edit Issues**
   - **Add Comments**

Now that you've configured the permission scheme, it's time to assign it to your Jira projects.

## Assign the permission scheme to your projects

A permission scheme has no effect until it's associated with at least one project.
Repeat these steps for each Jira project you want the Jira issues integration to access.

To assign the permission scheme to a project:

1. In the upper-right corner, select **Administration** > **Projects**.
1. Select the project you want to configure.
1. In **Project settings**, select **Permissions**.
1. Select **Actions** > **Use a different scheme**.
1. Select the scheme you created, then select **Associate**.

You've done it! Now go to GitLab and [configure the Jira issues integration](configure.md)
using the `gitlab` username and password you created here.
