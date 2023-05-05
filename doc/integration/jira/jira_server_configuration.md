---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira Server credentials **(FREE)**

To [integrate Jira with GitLab](index.md), you can:

- Recommended. Create a separate Jira user account for your Jira projects to access projects in GitLab.
This Jira user account must have write access to your Jira projects. To create the
credentials, you must:

  1. [Create a Jira Server user](#create-a-jira-server-user).
  1. [Create a Jira Server group](#create-a-jira-server-group) for the user to belong to.
  1. [Create a permission scheme for your group](#create-a-permission-scheme-for-your-group).

- Use an existing Jira user account provided the user belongs to a Jira group that
has been granted the **Administer Projects** [permission scheme](#create-a-permission-scheme-for-your-group).

After you select a Jira user account for the integration, [configure GitLab](configure.md) to use the account.

## Create a Jira Server user

This process creates a user named `gitlab`:

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

After you create the user, create a group for it.

## Create a Jira Server group

After you [create a Jira Server user](#create-a-jira-server-user), create a
group to assign permissions to the user.

This process adds the `gitlab` user you created to a new group named `gitlab-developers`:

1. Sign in to your Jira instance as a Jira administrator.
1. On the top bar, in the upper-right corner, select the gear icon, then
   select **User Management**.
1. On the left sidebar, select **Groups**.

   ![Jira create new user](img/jira_create_new_group.png)

1. In the **Add group** section, enter a **Name** for the group (for example,
   `gitlab-developers`), and then select **Add group**.
1. To add the `gitlab` user to the `gitlab-developers` group, select **Edit members**.
   The `gitlab-developers` group should be listed in the leftmost box as a
   selected group.
<!-- vale gitlab.BadPlurals = NO -->
1. In the **Add members to selected group(s)** section, enter `gitlab`.
1. Select **Add selected users**.
   The `gitlab` user appears in the **Group member(s)**
   section.
<!-- vale gitlab.BadPlurals = YES -->

   ![Jira added user to group](img/jira_added_user_to_group.png)

Next, create a permission scheme for your group.

## Create a permission scheme for your group

After you [create the group in Jira](#create-a-jira-server-group), grant permissions to the group by creating a permission scheme:

1. Sign in to your Jira instance as a Jira administrator.
1. On the top bar, in the upper-right corner, select the gear icon, then
   select **Issues**.
1. On the left sidebar, select **Permission Schemes**.
1. Select **Add Permission Scheme**, enter a **Name** and (optionally) a
   **Description**, and then select **Add**.
1. In the permissions scheme list, locate your new permissions scheme, and
   select **Permissions**.
1. Next to **Administer Projects**, select **Edit**.
1. From the **Group** dropdown list, select `gitlab-developers`, and then select **Grant**.

   ![Jira group access](img/jira_group_access.png)

Write down the new Jira username and its
password, as you need them when
[configuring GitLab](configure.md).
