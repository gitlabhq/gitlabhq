---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Create Jira Server username and password

We need to create a user account in Jira to have access to all projects that
need to integrate with GitLab.

The Jira user account created for the integration must have write access to
your Jira projects.

As an example, the following process creates a user named `gitlab` and that's a
member of a new group named `gitlab-developers`:

1. Sign in to your Jira instance as an administrator, and
   then go to the gear icon and select **User Management**.

   ![Jira user management link](img/jira_user_management_link.png)

1. Create a new user account (for example, `gitlab`) with write access to
   projects in Jira. Enter the user account's name and a valid e-mail address,
   because Jira sends a verification email to set up the password.

   Jira creates the username by using the email prefix. You can change the
   username later, if needed. The GitLab integration doesn't support SSO (such
   as SAML). You need to create an HTTP basic authentication password. You can
   do this by visiting the user profile, looking up the username, and setting a
   password.

   ![Jira create new user](img/jira_create_new_user.png)

1. From the sidebar, select **Groups**.

   ![Jira create new user](img/jira_create_new_group.png)

1. In the **Add group** section, enter a **Name** for the group (for example,
   `gitlab-developers`), and then select **Add group**.

1. Add the `gitlab` user to the `gitlab-developers` group by selecting **Edit members**.
   The `gitlab-developers` group should be listed in the leftmost box as a
   selected group. In the **Add members to selected group(s)** area, enter `gitlab`.

   ![Jira add user to group](img/jira_add_user_to_group.png)

   Select **Add selected users**, and `gitlab` should appear in the **Group member(s)**
   area. This membership is saved automatically.

   ![Jira added user to group](img/jira_added_user_to_group.png)

1. To give the newly-created group 'write' access, you must create a permission
   scheme. To do this, in the admin menu, go to the gear icon and select **Issues**.

1. From the sidebar, select **Permission Schemes**.

1. Select **Add Permission Scheme**, enter a **Name** and (optionally) a
   **Description**, and then select **Add**.

1. In the permissions scheme list, locate your new permissions scheme, and
   select **Permissions**. Next to **Administer Projects**, select **Edit**. In
   the **Group** list, select `gitlab-developers`.

   ![Jira group access](img/jira_group_access.png)

The Jira configuration is complete. Write down the new Jira username and its
password, as you'll need them when [configuring GitLab in the next section](jira.md#configuring-gitlab).
