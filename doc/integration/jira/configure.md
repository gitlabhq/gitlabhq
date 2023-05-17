---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira issue integration **(FREE)**

The Jira issue integration connects one or more GitLab projects to a Jira instance. You can host the Jira instance yourself or in [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud). The supported Jira versions are `6.x`, `7.x`, `8.x`, and `9.x`.

## Configure the integration

Prerequisites:

- Your GitLab installation must not use a [relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-relative-url-for-gitlab).
- **For Jira Cloud**, you must have a [Jira Cloud API token](#create-a-jira-cloud-api-token) and
  the email address you used to create the token.
- **For Jira Data Center or Jira Server**, you must have one of the following:
  - [Jira username and password](jira_server_configuration.md).
  - Jira personal access token.

You can enable the Jira issue integration by configuring your project settings in GitLab.
You can also configure these settings at the:

- [Group level](../../user/admin_area/settings/project_integration_management.md#manage-group-level-default-settings-for-a-project-integration)
- [Instance level](../../user/admin_area/settings/project_integration_management.md#manage-instance-level-default-settings-for-a-project-integration) for self-managed GitLab

To configure your project settings in GitLab:

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
   - **Web URL**: Base URL for the Jira instance web interface you're linking to
     this GitLab project (for example, `https://jira.example.com`).
   - **Jira API URL**: Base URL for the Jira instance API (for example, `https://jira-api.example.com`).
     If this URL is not set, the **Web URL** value is used by default. For Jira Cloud, leave **Jira API URL** blank.
   - **Authentication type**: From the dropdown list, select:
     - **Basic**
     - **Jira personal access token (Jira Data Center and Jira Server only)**
   - **Email or username** (relevant to **Basic** authentication only):
     - For Jira Cloud, enter an email.
     - For Jira Data Center or Jira Server, enter a username.
   - **New API token, password, or Jira personal access token**:
     - For **Basic** authentication:
         - For Jira Cloud, enter an API token.
         - For Jira Data Center or Jira Server, enter a password.
     - For **Jira personal access token** authentication, enter a personal access token.
1. To enable users to [view Jira issues](issues.md#view-jira-issues) inside the GitLab project, select **Enable Jira issues** and
   enter a Jira project key.

   You can display issues only from a single Jira project in a given GitLab project.

   WARNING:
   If you enable Jira issues with this setting, all users with access to this GitLab project
   can view all issues from the specified Jira project.

1. To enable [issue creation for vulnerabilities](../../user/application_security/vulnerabilities/index.md#create-a-jira-issue-for-a-vulnerability), select **Enable Jira issue creation from vulnerabilities**.
1. Select the **Jira issue type**. If the dropdown list is empty, select **Refresh** (**{retry}**) and try again.
1. To verify the Jira connection is working, select **Test settings**.
1. Select **Save changes**.

Your GitLab project can now interact with all Jira projects in your instance, and the project
displays a Jira link that opens the Jira project.

## Create a Jira Cloud API token

To configure the Jira issue integration for Jira Cloud, you must have a Jira Cloud API token.
To create a Jira Cloud API token:

1. Sign in to [Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens)
   from an account with **write** access to Jira projects.

   The link opens the **API tokens** page. Alternatively, from your Atlassian
   profile, select **Account Settings > Security > Create and manage API tokens**.

1. Select **Create API token**.
1. In the dialog, enter a label for your token and select **Create**.

To copy the API token, select **Copy** and paste the token somewhere safe.

## Migrate from Jira Server to Jira Cloud in GitLab

To migrate from Jira Server to Jira Cloud in GitLab and maintain your Jira integration:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Jira**.
1. In **Web URL**, enter the new Jira site URL (for example, `https://myjirasite.atlassian.net`).
1. In **Username or Email**, enter the username or email registered on your Jira profile.
1. [Create a Jira Cloud API token](#create-a-jira-cloud-api-token), and copy the token value.
1. In **Password or API token**, paste the API token value.
1. Optional. Select **Test settings** to check if the connection is working.
1. Select **Save changes**.

To update existing Jira issue references in GitLab to use the new Jira site URL, you must [invalidate the Markdown cache](../../administration/invalidate_markdown_cache.md#invalidate-the-cache).
