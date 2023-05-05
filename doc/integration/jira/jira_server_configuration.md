---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira Server credentials **(FREE)**

To [integrate Jira with GitLab](configure.md), you should create a separate Jira user account for your Jira projects
to access projects in GitLab. This Jira user account must have write access to your Jira projects.
To create the credentials:

1. [Create a Jira Server user](#create-a-jira-server-user).
1. [Create a Jira Server group for the user](#create-a-jira-server-group-for-the-user).
1. [Create a permission scheme for the group](#create-a-permission-scheme-for-the-group).

Alternatively, you can use an existing Jira user account, provided the user belongs to a Jira group that
has been granted the **Administer Projects** [permission scheme](#create-a-permission-scheme-for-the-group).

After you select a Jira user account, [configure the integration](configure.md#configure-the-integration) in GitLab to use the account.

## Create a Jira Server user

To create a Jira Server user:

1. Sign in to your Jira instance as a Jira administrator.
1. On the top bar, in the upper-right corner, select the gear icon, then
   select **User Management**.
1. [Create a new user account manually](https://confluence.atlassian.com/adminjiraserver/create-edit-or-remove-a-user-938847025.html#Create,edit,orremoveauser-CreateusersmanuallyinJira) with write access to
   projects in Jira.
   - **Email address**: You should use a valid email address.
   - **Username**: Set the username to `gitlab`.
   - **Password**: You must set a password because the Jira issue integration does not
     support SSO such as SAML.
1. Select **Create user**.

Now that you've created a user named `gitlab`, it's time to create a group for the user.

## Create a Jira Server group for the user

To create a Jira Server group for the user:

1. Sign in to your Jira instance as a Jira administrator.
1. On the top bar, in the upper-right corner, select the gear icon, then
   select **User Management**.
1. On the left sidebar, select **Groups**.
1. In the **Add group** section, enter a **Name** for the group (for example,
   `gitlab-developers`), then select **Add group**.
1. To add the `gitlab` user to the `gitlab-developers` group, select **Edit members**.
   The `gitlab-developers` group appears as a selected group.
<!-- vale gitlab.BadPlurals = NO -->
1. In the **Add members to selected group(s)** section, enter `gitlab`.
1. Select **Add selected users**.
   The `gitlab` user appears as a group member.
<!-- vale gitlab.BadPlurals = YES -->

Now that you've added the `gitlab` user to a new group named `gitlab-developers`,
it's time to create a permission scheme for the group.

## Create a permission scheme for the group

To create a permission scheme for the group:

1. Sign in to your Jira instance as a Jira administrator.
1. On the top bar, in the upper-right corner, select the gear icon, then
   select **Issues**.
1. On the left sidebar, select **Permission Schemes**.
1. Select **Add Permission Scheme**, enter a **Name** and (optionally) a
   **Description**, then select **Add**.
1. In the permissions scheme list, locate your new permissions scheme, and
   select **Permissions**.
1. Next to **Administer Projects**, select **Edit**.
1. From the **Group** dropdown list, select `gitlab-developers`, then select **Grant**.

You need the new Jira username and password when you [configure the integration](configure.md#configure-the-integration) in GitLab.
