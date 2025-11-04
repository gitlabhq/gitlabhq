---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira issues integration
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Name [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555) to Jira issues integration in GitLab 17.6.

{{< /history >}}

The Jira issues integration connects one or more GitLab projects to a Jira instance.
You can host the Jira instance yourself or in [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud).
The supported Jira versions are `6.x`, `7.x`, `8.x`, `9.x`, and `10.x`.

## Configure the integration

{{< history >}}

- Authentication with Jira personal access tokens [introduced](https://gitlab.com/groups/gitlab-org/-/epics/8222) in GitLab 16.0.
- **Jira issues** and **Jira issues for vulnerabilities** sections [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440430) in GitLab 16.10 [with a flag](../../administration/feature_flags/_index.md) named `jira_multiple_project_keys`. Disabled by default.
- **Jira issues** and **Jira issues for vulnerabilities** sections [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753) in GitLab 17.0. Feature flag `jira_multiple_project_keys` removed.
- **Enable Jira issues** checkbox [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055) to **View Jira issues** in GitLab 17.0.
- **Enable Jira issue creation from vulnerabilities** checkbox [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055) to **Create Jira issues for vulnerabilities** in GitLab 17.0.
- **Customize Jira issues** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/478824) in GitLab 17.5.

{{< /history >}}

Prerequisites:

- Your GitLab installation must not use a [relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-relative-url-for-gitlab).
- **For Jira Cloud**:
  - You must have a [Jira Cloud API token](#create-a-jira-cloud-api-token) and the email address you used to create the token.
  - If you've enabled
    [IP allowlists](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), add the
    [GitLab.com IP range](../../user/gitlab_com/_index.md#ip-range) to the allowlist to [view Jira issues](#view-jira-issues) in GitLab.
- **For Jira Data Center or Jira Server**, you must have one of the following:
  - [Jira username and password](jira_server_configuration.md).
  - Jira personal access token (GitLab 16.0 and later).

You can enable the Jira issues integration by configuring your project settings in GitLab.
You can also configure the integration for a specific
[group](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration) or an entire
[instance](../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration)
on GitLab Self-Managed.

With this integration, your GitLab project can interact with all Jira projects on your instance.
To configure your project settings in GitLab:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select **Jira issues**.
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
1. Optional. To [view Jira issues](#view-jira-issues) in GitLab,
   in the **Jira issues** section:
   1. Select the **View Jira issues** checkbox.

      {{< alert type="warning" >}}

      When you enable this setting, all users with access to your GitLab project
      can view all issues from the Jira projects you've specified.

      {{< /alert >}}

   1. Enter one or more Jira project keys.
      Leave blank to include all available keys.
1. Optional. To [create Jira issues for vulnerabilities](#create-a-jira-issue-for-a-vulnerability),
   in the **Jira issues for vulnerabilities** section:
   1. Select the **Create Jira issues for vulnerabilities** checkbox.

      {{< alert type="note" >}}

      You can enable this setting only for individual projects and groups.

      {{< /alert >}}

   1. Enter a Jira project key.
   1. Select **Fetch issue types for this project key** ({{< icon name="retry" >}}),
      then select the type of Jira issues to create.
   1. Optional. Select the **Customize Jira issues** checkbox to be able to review, modify, or add details
      to a Jira issue when it's created for a vulnerability.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

## View Jira issues

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- Enabling Jira issues for a group [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325715) in GitLab 16.9.
- Viewing issues from multiple Jira projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440430) in GitLab 16.10 [with a flag](../../administration/feature_flags/_index.md) named `jira_multiple_project_keys`. Disabled by default.
- Viewing issues from multiple Jira projects [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753) in GitLab 17.0. Feature flag `jira_multiple_project_keys` removed.

{{< /history >}}

Prerequisites:

- Ensure the Jira issues integration is [configured](#configure-the-integration)
  and the **View Jira issues** checkbox is selected.

You can enable Jira issues for a specific group or project, but you can view the issues in GitLab projects only.
To view issues from one or more Jira projects in a GitLab project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Plan** > **Jira issues**.

By default, the issues are sorted by **Created date**.
The most recently created issues appear at the top.
You can [filter issues](#filter-jira-issues) and select an issue to view that issue in GitLab.

Issues are grouped into the following tabs based on their
[Jira status](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html):

- **Open**: issues with any Jira status other than **Done**.
- **Closed**: issues with a **Done** Jira status.
- **All**: issues with any Jira status.

### Filter Jira issues

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- Filtering Jira issues by project [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440430) in GitLab 16.10 [with a flag](../../administration/feature_flags/_index.md) named `jira_multiple_project_keys`. Disabled by default.
- Filtering Jira issues by project [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753) in GitLab 17.0. Feature flag `jira_multiple_project_keys` removed.

{{< /history >}}

Prerequisites:

- Ensure the Jira issues integration is [configured](#configure-the-integration)
  and the **View Jira issues** checkbox is selected.

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
- **Project**: specify the Jira project key in the `project` parameter in the URL
  (for example, `/-/integrations/jira/issues?project=GTL`).

## Jira verification

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192795) in GitLab 18.3.

{{< /history >}}

Prerequisites:

- Ensure the Jira issues integration is [configured](#configure-the-integration)
  and the **View Jira issues** checkbox is selected.

You can set up verification rules to ensure Jira issues referenced in commit messages meet specific criteria before allowing pushes. This feature helps maintain consistent workflows between GitLab and Jira.

To configure Jira verification:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select **Jira issues**.
1. Go to the **Jira verification** section.
1. Configure the following verification checks:
   - **Check issue exists**: Verifies that the Jira issue referenced in the commit message exists in Jira.
   - **Check assignee**: Verifies that the committer is the assignee of the Jira issue referenced in the commit message.
   - **Check issue status**: Verifies that the Jira issue referenced in the commit message has one of the allowed statuses.
   - **Allowed statuses**: A comma-separated list of allowed Jira issue statuses (for example, `Ready, In Progress, Review`). This field is only available when **Check issue status** is enabled.
1. Select **Save changes**.

When a user attempts to push changes that don't meet the verification criteria, GitLab displays an error message indicating why the push was rejected.

{{< alert type="note" >}}

If a commit message contains multiple Jira issue keys, only the first one is used for verification checks.

{{< /alert >}}

### Example error messages

- If a referenced Jira issue doesn't exist (when **Check issue exists** is enabled):

  ```plaintext
  Jira issue PROJECT-123 does not exist.
  ```

- If a referenced Jira issue isn't assigned to the committer (when **Check assignee** is enabled):

  ```plaintext
  Jira issue PROJECT-123 is not assigned to you. It is assigned to Jane Doe.
  ```

- If a referenced Jira issue has a status that's not in the allowed list (when **Check issue status** is enabled):

  ```plaintext
  Jira issue PROJECT-123 has status 'Done', which is not in the list of allowed statuses: Ready, In Progress, Review.
  ```

### Use case for verification checks

Consider this example:

1. Your team uses a workflow where Jira issues should be in a specific status when actively being worked on.
1. You configure Jira verification to:
   - Check that issues exist
   - Verify that issues are in an "In Progress" or "Review" status
1. A developer tries to push changes with the commit message "Fix PROJECT-123 by adding validation".
1. GitLab checks that:
   - The Jira issue PROJECT-123 exists
   - The issue has a status of either "In Progress" or "Review"
1. If all checks pass, the push is allowed. If any check fails, the push is rejected with an error message.

This ensures your team follows the correct workflow by preventing code changes from being pushed when the corresponding Jira issue isn't in the right state.

## Create a Jira issue for a vulnerability

{{< details >}}

- Tier: Ultimate

{{< /details >}}

Prerequisites:

- Ensure the Jira issues integration is [configured](#configure-the-integration)
  and the **Create Jira issues for vulnerabilities** checkbox is selected.
- You must have a Jira user account with permission to create issues in the target project.

You can create a Jira issue from GitLab to track any action taken to resolve or mitigate a vulnerability.
To create a Jira issue for a vulnerability:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Vulnerability report**.
1. Select the vulnerability's description.
1. Select **Create Jira issue**.

   If the [**Customize Jira issues**](#configure-the-integration) setting is selected, you will be redirected to the issue creation form on your Jira instance, pre-filled with vulnerability data. You can review, modify, or add details before creating the Jira issue.

The issue is created in the target Jira project with information from the vulnerability report.

To create a GitLab issue, see [Create a GitLab issue for a vulnerability](../../user/application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability).

## Create a Jira Cloud API token

To configure the Jira issues integration for Jira Cloud, you must have a Jira Cloud API token.
To create a Jira Cloud API token:

1. Sign in to [Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens)
   from an account with write access to Jira projects.

   The link opens the **API tokens** page. Alternatively, from your Atlassian
   profile, select **Account Settings** > **Security** > **Create and manage API tokens**.

1. Select **Create API token**.
1. On the dialog, enter a label for your token and select **Create**.

To copy the API token, select **Copy**.

## Migrate from one Jira site to another

{{< history >}}

- Integration name [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555) to **Jira issues** in GitLab 17.6.

{{< /history >}}

To migrate from one Jira site to another in GitLab and maintain your Jira issues integration:

1. Follow the steps in [configure the integration](#configure-the-integration).
1. Enter the new Jira site URL (for example, `https://myjirasite.atlassian.net`).

In GitLab 18.6 and later, existing Jira issue references are automatically updated to use the new Jira site URL.

In GitLab 18.5 and earlier, you must
[invalidate the Markdown cache](../../administration/invalidate_markdown_cache.md#invalidate-the-cache) to update existing Jira issue references.
