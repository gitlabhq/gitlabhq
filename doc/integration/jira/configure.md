---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira issue integration **(FREE ALL)**

The Jira issue integration connects one or more GitLab projects to a Jira instance. You can host the Jira instance yourself or in [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud). The supported Jira versions are `6.x`, `7.x`, `8.x`, and `9.x`.

## Configure the integration

> Authentication with Jira personal access tokens [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8222) in GitLab 16.0.

Prerequisites:

- Your GitLab installation must not use a [relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-relative-url-for-gitlab).
- **For Jira Cloud**:
  - You must have a [Jira Cloud API token](#create-a-jira-cloud-api-token) and the email address you used to create the token.
  - If you've enabled
  [IP allowlists](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), add the
  [GitLab.com IP range](../../user/gitlab_com/index.md#ip-range) to the allowlist to [view Jira issues](issues.md#view-jira-issues) in GitLab.
- **For Jira Data Center or Jira Server**, you must have one of the following:
  - [Jira username and password](jira_server_configuration.md).
  - Jira personal access token (GitLab 16.0 and later).

You can enable the Jira issue integration by configuring your project settings in GitLab.
You can also configure these settings at the:

- [Instance level](../../administration/settings/project_integration_management.md#manage-instance-level-default-settings-for-a-project-integration) (self-managed GitLab)
- [Group level](../../user/project/integrations/index.md#manage-group-level-default-settings-for-a-project-integration)

To configure your project settings in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Jira**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Provide connection details:
   - **Web URL**: Base URL for the Jira instance web interface you're linking to
     this GitLab project (for example, `https://jira.example.com`).
   - **Jira API URL**: Base URL for the Jira instance API (for example, `https://jira-api.example.com`).
     If this URL is not set, the **Web URL** value is used by default. For Jira Cloud, leave **Jira API URL** blank.
   - **Authentication method**:
     - **Basic**:
       - **Email or username**:
          - For Jira Cloud, enter an email.
          - For Jira Data Center or Jira Server, enter a username.
       - **API token or password**:
          - For Jira Cloud, enter an API token.
          - For Jira Data Center or Jira Server, enter a password.
     - **Jira personal access token** (only available for Jira Data Center and Jira Server): Enter a personal access token.
1. Provide trigger settings:
   - Select **Commit**, **Merge request**, or both as triggers. When you mention a Jira issue ID in GitLab,
   GitLab links to that issue.
   - To add a comment to the Jira issue that links back to GitLab, select the
   **Enable comments** checkbox and the information that the comment displays.
   - To [transition Jira issues automatically](../../user/project/issues/managing_issues.md#closing-issues-automatically) in GitLab,
   select the **Enable Jira transitions** checkbox.
1. In the **Jira issue matching** section:
   - For **Jira issue regex**, [enter a regex pattern](issues.md#define-a-regex-pattern).
   - For **Jira issue prefix**, [enter a prefix](issues.md#define-a-prefix).
1. In the **Issues** section:
   - To [view Jira issues](issues.md#view-jira-issues) in GitLab, select the **Enable Jira issues** checkbox and
   enter a Jira project key. You can only view issues from a single Jira project in a GitLab project.

   WARNING:
   When you enable this setting, all users with access to that GitLab project
   can view all issues from the Jira project you've specified.

   - To [create Jira issues for vulnerabilities](#create-a-jira-issue-for-a-vulnerability), select the **Enable Jira issue creation from vulnerabilities** checkbox.

   NOTE:
   You can enable this setting at the project level only.

1. Optional. Select **Test settings**.
1. Select **Save changes**.

Your GitLab project can now interact with all Jira projects in your instance, and the project
displays a Jira link that opens the Jira project.

## Create a Jira issue for a vulnerability **(ULTIMATE ALL)**

Prerequisites:

- Ensure the Jira issue integration is [configured](#configure-the-integration) and the
  **Enable Jira issue creation from vulnerabilities** checkbox is selected.
- You must have a Jira user account with permission to create issues in the target project.

You can create a Jira issue to track any action taken to resolve or mitigate a vulnerability.

To create a Jira issue for a vulnerability:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Vulnerability report**.
1. Select the vulnerability's description.
1. Select **Create Jira issue**.

A Jira issue is created in the project with information from the vulnerability report.

To create a GitLab issue, see [Create a GitLab issue for a vulnerability](../../user/application_security/vulnerabilities/index.md#create-a-gitlab-issue-for-a-vulnerability).

## Create a Jira Cloud API token

To configure the Jira issue integration for Jira Cloud, you must have a Jira Cloud API token.
To create a Jira Cloud API token:

1. Sign in to [Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens)
   from an account with write access to Jira projects.

   The link opens the **API tokens** page. Alternatively, from your Atlassian
   profile, select **Account Settings > Security > Create and manage API tokens**.

1. Select **Create API token**.
1. On the dialog, enter a label for your token and select **Create**.

To copy the API token, select **Copy**.

## Migrate from Jira Server to Jira Cloud in GitLab

To migrate from Jira Server to Jira Cloud in GitLab and maintain your Jira integration:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Jira**.
1. In **Web URL**, enter the new Jira site URL (for example, `https://myjirasite.atlassian.net`).
1. In **Email or username**, enter the email registered on your Jira profile.
1. [Create a Jira Cloud API token](#create-a-jira-cloud-api-token), and copy the token value.
1. In **API token or password**, paste the API token value.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

To update existing Jira issue references in GitLab to use the new Jira site URL, you must [invalidate the Markdown cache](../../administration/invalidate_markdown_cache.md#invalidate-the-cache).
