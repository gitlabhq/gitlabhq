---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure the Jira integration in GitLab **(FREE)**

You can set up the [Jira integration](index.md#jira-integration)
by configuring your project settings in GitLab.
You can also configure these settings at a [group level](../../user/admin_area/settings/project_integration_management.md#manage-group-level-default-settings-for-a-project-integration),
and for self-managed GitLab, at an [instance level](../../user/admin_area/settings/project_integration_management.md#manage-instance-level-default-settings-for-a-project-integration).

Prerequisites:

- Ensure your GitLab installation does not use a [relative URL](development_panel.md#limitations).
- For **Jira Server**, ensure you have a Jira username and password.
  See [authentication in Jira](index.md#authentication-in-jira).
- For **Jira on Atlassian cloud**, ensure you have an API token
  and the email address you used to create the token.
  See [authentication in Jira](index.md#authentication-in-jira).

To configure your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Jira**.
1. Select **Enable integration**.
1. Select **Trigger** actions. Your choice determines whether a mention of Jira issue
   (in a GitLab commit, merge request, or both) creates a cross-link in Jira back to GitLab.
1. To comment in the Jira issue when a **Trigger** action is made in GitLab, select
   **Enable comments**.
1. To transition Jira issues when a
   [closing reference](../../user/project/issues/managing_issues.md#closing-issues-automatically)
   is made in GitLab, select **Enable Jira transitions**.
1. Provide Jira configuration information:
   - **Web URL**: The base URL to the Jira instance web interface you're linking to
     this GitLab project, such as `https://jira.example.com`.
   - **Jira API URL**: The base URL to the Jira instance API, such as `https://jira-api.example.com`.
     Defaults to the **Web URL** value if not set. Leave blank if using **Jira on Atlassian cloud**.
   - **Username or Email**:
     For **Jira Server**, use `username`. For **Jira on Atlassian cloud**, use `email`.
   - **Password/API token**:
     Use `password` for **Jira Server** or `API token` for **Jira on Atlassian cloud**.
1. To enable users to [view Jira issues](issues.md#view-jira-issues) inside the GitLab project, select **Enable Jira issues** and
   enter a Jira project key.

   You can display issues only from a single Jira project in a given GitLab project.

   WARNING:
   If you enable Jira issues with this setting, all users with access to this GitLab project
   can view all issues from the specified Jira project.

1. To enable [issue creation for vulnerabilities](../../user/application_security/vulnerabilities/index.md#create-a-jira-issue-for-a-vulnerability), select **Enable Jira issue creation from vulnerabilities**.
1. Select the **Jira issue type**. If the dropdown list is empty, select refresh (**{retry}**) and try again.
1. To verify the Jira connection is working, select **Test settings**.
1. Select **Save changes**.

Your GitLab project can now interact with all Jira projects in your instance and the project now
displays a Jira link that opens the Jira project.

## Migrate from Jira Server to Jira Cloud in GitLab

To migrate from Jira Server to Jira Cloud in GitLab and maintain your Jira integration:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Jira**.
1. In **Web URL**, enter the new Jira site URL (for example, `https://myjirasite.atlassian.net`).
1. In **Username or Email**, enter the username or email registered on your Jira profile.
1. [Create an API token](jira_cloud_configuration.md), and copy that value.
1. In **Password or API token**, paste the API token value.
1. Optional. Select **Test settings** to check if the connection is working.
1. Select **Save changes**.
