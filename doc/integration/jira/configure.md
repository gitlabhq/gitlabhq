---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira issue integration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The Jira issue integration connects one or more GitLab projects to a Jira instance.
You can host the Jira instance yourself or in [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud).
The supported Jira versions are `6.x`, `7.x`, `8.x`, and `9.x`.

## Configure the integration

> - Authentication with Jira personal access tokens [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8222) in GitLab 16.0.

Prerequisites:

- Your GitLab installation must not use a [relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-relative-url-for-gitlab).
- **For Jira Cloud**:
  - You must have a [Jira Cloud API token](#create-a-jira-cloud-api-token) and the email address you used to create the token.
  - If you've enabled
    [IP allowlists](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), add the
    [GitLab.com IP range](../../user/gitlab_com/index.md#ip-range) to the allowlist to [view Jira issues](#view-jira-issues) in GitLab.
- **For Jira Data Center or Jira Server**, you must have one of the following:
  - [Jira username and password](jira_server_configuration.md).
  - Jira personal access token (GitLab 16.0 and later).

You can enable the Jira issue integration by configuring your project settings in GitLab.
You can also configure the integration at the
[group level](../../user/project/integrations/index.md#manage-group-level-default-settings-for-a-project-integration) and the
[instance level](../../administration/settings/project_integration_management.md#manage-instance-level-default-settings-for-a-project-integration)
on self-managed GitLab.

With this integration, your GitLab project can interact with all Jira projects on your instance.
To configure your project settings in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Jira**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Provide connection details:
   - **Web URL**: Base URL for the Jira instance web interface you're linking
     to this GitLab project (for example, `https://jira.example.com`).
   - **Jira API URL**: Base URL for the Jira instance API (for example, `https://jira-api.example.com`).
     If this URL is not set, the **Web URL** value is used by default.
     For Jira Cloud, leave **Jira API URL** blank.
   - **Authentication method**:
     - **Basic**:
       - **Email or username**:
         - For Jira Cloud, enter an email.
         - For Jira Data Center or Jira Server, enter a username.
       - **API token or password**:
         - For Jira Cloud, enter an API token.
         - For Jira Data Center or Jira Server, enter a password.
     - **Jira personal access token** (only available for Jira Data Center and Jira Server):
       Enter a personal access token.
1. Provide trigger settings:
   - Select **Commit**, **Merge request**, or both as triggers.
     When you mention a Jira issue ID in GitLab, GitLab links to that issue.
   - To add a comment to the Jira issue that links back to GitLab,
     select the **Enable comments** checkbox.
   - To [transition Jira issues automatically](../../user/project/issues/managing_issues.md#closing-issues-automatically) in GitLab,
     select the **Enable Jira transitions** checkbox.
1. In the **Jira issue matching** section:
   - For **Jira issue regex**, [enter a regex pattern](issues.md#define-a-regex-pattern).
   - For **Jira issue prefix**, [enter a prefix](issues.md#define-a-prefix).
1. Optional. In the **Issues** section:
   - To [view Jira issues](#view-jira-issues) in GitLab:
     1. Select the **Enable Jira issues** checkbox.

        WARNING:
        When you enable this setting, all users with access to your GitLab project
        can view all issues from the Jira project you've specified.

     1. Enter the Jira project key.
   - To [create Jira issues for vulnerabilities](#create-a-jira-issue-for-a-vulnerability):
     1. Select the **Enable Jira issue creation from vulnerabilities** checkbox.

        NOTE:
        You can enable this setting at the project and group levels only.

     1. Select the type of Jira issues to create.

        WARNING:
        Before you select the issue type, you must enter
        the Jira project key and select **Save changes**.

1. Optional. Select **Test settings**.
1. Select **Save changes**.

## View Jira issues

DETAILS:
**Tier:** Premium, Ultimate

> - Ability to enable Jira issues at the group level [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325715) in GitLab 16.9.

Prerequisites:

- Ensure the Jira issue integration is [configured](#configure-the-integration)
  and the **Enable Jira issues** checkbox is selected.

To view issues from a single Jira project in a GitLab project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Jira issues**.

By default, the issues are sorted by **Created date**.
The most recently created issues appear at the top.
You can [filter issues](#filter-jira-issues) and select an issue to view that issue in GitLab.

Issues are grouped into the following tabs based on their
[Jira status](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html):

- **Open**: issues with any Jira status other than **Done**.
- **Closed**: issues with a **Done** Jira status.
- **All**: issues with any Jira status.

### Filter Jira issues

DETAILS:
**Tier:** Premium, Ultimate

Prerequisites:

- Ensure the Jira issue integration is [configured](#configure-the-integration)
  and the **Enable Jira issues** checkbox is selected.

When you [view Jira issues](#view-jira-issues) in GitLab,
you can filter the issues by text in summaries and descriptions.
You can also filter the issues by:

- **Label**: specify one or more Jira issue labels in the `labels[]` parameter in the URL.
  When you specify multiple labels, only the issues that have all the specified labels appear
  (for example, `/-/integrations/jira/issues?labels[]=backend&labels[]=feature&labels[]=QA`).
- **Status**: specify the Jira issue status in the `status` parameter in the URL
  (for example, `/-/integrations/jira/issues?status=In Progress`).
- **Reporter**: specify the Jira display name of the `author_username` parameter in the URL
  (for example, `/-/integrations/jira/issues?author_username=John Smith`).
- **Assignee**: specify the Jira display name of the `assignee_username` parameter in the URL
  (for example, `/-/integrations/jira/issues?assignee_username=John Smith`).
- **Project**: specify the [Jira project key](#multiple-jira-project-keys) in the `project` parameter in the URL
  (for example, `/-/integrations/jira/issues?project=GTL`).

### Multiple Jira project keys

DETAILS:
**Tier:** Premium, Ultimate

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440430) in GitLab 16.11 [with a flag](../../administration/feature_flags.md) named `jira_multiple_project_keys`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can enable the feature flag named `jira_multiple_project_keys`.
On GitLab.com and GitLab Dedicated, this feature is not available.

When you enable `jira_multiple_project_keys`, you can:

- [View issues](#view-jira-issues) from multiple Jira projects in a GitLab project.
- [Filter Jira issues](#filter-jira-issues) by project.

In **Jira project keys**, you can enter up to 100 project keys separated by commas.
Leave blank to include all available keys.

## Create a Jira issue for a vulnerability

DETAILS:
**Tier:** Ultimate

Prerequisites:

- Ensure the Jira issue integration is [configured](#configure-the-integration) and the
  **Enable Jira issues** and **Enable Jira issue creation from vulnerabilities** checkboxes are selected.
- You must have a Jira user account with permission to create issues in the target project.

You can create a Jira issue from GitLab to track any action taken to resolve or mitigate a vulnerability.
To create a Jira issue for a vulnerability:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Vulnerability report**.
1. Select the vulnerability's description.
1. Select **Create Jira issue**.

The issue is created in the target Jira project with information from the vulnerability report.

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

## Migrate from Jira Server to Jira Cloud

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

To update existing Jira issue references in GitLab to use the new Jira site URL, you must
[invalidate the Markdown cache](../../administration/invalidate_markdown_cache.md#invalidate-the-cache).
