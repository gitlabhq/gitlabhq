---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Create Jira credentials'
---

This tutorial shows you how to create Jira credentials. You can use your new Jira credentials to
configure the [Jira issues integration](configure.md) in GitLab for Jira Data Center or Jira Server.

To create Jira credentials, here's what we're going to do:

1. [Create a Jira user](#create-a-jira-user).
1. [Create a Jira group for the user](#create-a-jira-group-for-the-user).
1. [Create a permission scheme for the group](#create-a-permission-scheme-for-the-group).

Prerequisites:

- You must have at least the `Jira Administrators` [global permission](https://confluence.atlassian.com/adminjiraserver/managing-global-permissions-938847142.html).

## Create a Jira user

To create a Jira user:

1. On the top bar, in the upper-right corner, select **Administration** (**{settings}**) > **User management**.
1. [Create a new user account](https://confluence.atlassian.com/adminjiraserver/create-edit-or-remove-a-user-938847025.html#Create,edit,orremoveauser-CreateusersmanuallyinJira) with write access to your Jira projects.

   Alternatively, you can use an existing user account, provided the user belongs to a Jira group that has been granted
   the `Administer Projects` [permission scheme](#create-a-permission-scheme-for-the-group).

   - In **Email address**, enter a valid email address.
   - In **Username**, enter `gitlab`.
   - In **Password**, enter a password (the Jira issues integration does not support SSO such as SAML).
1. Select **Create user**.

Now that you've created a user named `gitlab`, it's time to create a group for the user.

## Create a Jira group for the user

To create a Jira group for the user:

1. On the top bar, in the upper-right corner, select **Administration** (**{settings}**) > **User management**.
1. On the left sidebar, select **Groups**.
1. In the **Add group** section, enter a name for the group (for example,
   `gitlab-developers`), then select **Add group**.
1. To add the `gitlab` user to the new `gitlab-developers` group, select **Edit members**.
   The `gitlab-developers` group appears as a selected group.
<!-- vale gitlab_base.BadPlurals = NO -->
1. In the **Add members to selected group(s)** section, enter `gitlab`.
<!-- vale gitlab_base.BadPlurals = YES -->
1. Select **Add selected users**.
   The `gitlab` user appears as a group member.

Now that you've added the `gitlab` user to a new group named `gitlab-developers`,
it's time to create a permission scheme for the group.

## Create a permission scheme for the group

To create a permission scheme for the group:

1. On the top bar, in the upper-right corner, select **Administration** (**{settings}**) > **Issues**.
1. On the left sidebar, select **Permission schemes**.
1. Select **Add permission scheme**.
1. On the **Add permission scheme** dialog:
   - Enter a name for the scheme.
   - Optional. Enter a description for the scheme.
1. Select **Add**.
1. On the **Permission schemes** page, in the **Actions** column, select **Permissions** for the new scheme.
1. Next to **Administer Projects**, select **Edit**.
1. On the **Grant permission** dialog, for **Granted to**, select **Group**.
1. From the **Group** dropdown list, select `gitlab-developers`, then select **Grant**.

You've done it! You can now use your new Jira username and password to configure the
[Jira issues integration](configure.md) in GitLab for Jira Data Center or Jira Server.
