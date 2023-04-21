---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira DVCS connector **(FREE)**

WARNING:
The Jira DVCS connector for Jira Cloud was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/362168) in GitLab 15.1
and is planned for removal in 16.0. Use the [GitLab for Jira Cloud app](../connect-app.md) instead.
The Jira DVCS connector was also deprecated for Jira 8.13 and earlier. You can only use the Jira DVCS connector with Jira Server or Jira Data Center in Jira 8.14 and later. Upgrade your Jira instance to Jira 8.14 or later, and reconfigure the Jira integration in your GitLab instance.

Use the Jira DVCS (distributed version control system) connector if you self-host
your Jira instance with Jira Server or Jira Data Center and want to sync information between GitLab and Jira.
If you're on Jira Cloud, [migrate to the GitLab for Jira Cloud app](#migrate-to-the-gitlab-for-jira-cloud-app).

When you configure the Jira DVCS connector, make sure your GitLab and Jira instances
are accessible.

- **Self-managed GitLab**: Your GitLab instance must be accessible by Jira.
- **Jira Server**: Your network must allow access to your instance.

## Smart Commits

When connecting GitLab and Jira with the Jira DVCS connector, you can process your Jira issues with
special commands called [Smart Commits](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/).
With Smart Commits, you can:

- Comment on issues.
- Record time-tracking information against issues.
- Transition issues to any status defined in the Jira project's workflow.

Commands must be in the first line of the commit message. For more information about how Smart Commits work and what commands are available
for use, see the [Atlassian documentation](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/).

For Smart Commits to work, the GitLab user must have a corresponding
Jira user with the same email address or username.

### Smart Commit syntax

Smart Commits must follow this pattern:

```plaintext
<ISSUE_KEY> <ignored text> #<command> <optional command parameters>
```

Some examples:

- Add a comment to a Jira issue: `KEY-123 fixes a bug #comment Bug is fixed.`
- Record time tracking: `KEY-123 #time 2w 4d 10h 52m Tracking work time.`
- Close an issue: `KEY-123 #close Closing issue`

A Smart Commit message must not span more than one line (no carriage returns), but
you can still perform multiple actions in a single commit. For example:

- Add time tracking, add a comment, and transition to **Closed**:

  ```plaintext
  KEY-123 #time 2d 5h #comment Task completed ahead of schedule #close
  ```

- Add a comment, transition to **In-progress**, and add time tracking:

  ```plaintext
  KEY-123 #comment started working on the issue #in-progress #time 12d 5h
  ```

## Configure a GitLab application for DVCS

For projects in a single group, you should create a [group application](../../oauth_provider.md#create-a-group-owned-application).

For projects across multiple groups, you should create a new user account in GitLab for Jira integration work only.
A separate account ensures regular account maintenance does not affect your integration.

If a separate user account or group application is not possible, you can set up this integration
as an [instance-wide application](../../oauth_provider.md#create-an-instance-wide-application)
or with a [user-owned application](../../oauth_provider.md#create-a-user-owned-application).

1. Go to the [appropriate **Applications** section](../../oauth_provider.md).
1. In the **Name** text box, enter a descriptive name for the integration (for example, `Jira`).
1. In the **Redirect URI** text box, enter the generated **Redirect URL** from
   [linking GitLab accounts](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html).
1. In **Scopes**, select `api` and clear any other checkboxes.
   The Jira DVCS connector requires a **write-enabled** `api` scope to automatically create and manage required webhooks.
1. Select **Submit**.
1. Copy the **Application ID** and **Secret** values.
   You need these values to configure Jira.

## Configure Jira for DVCS

To import all GitLab commits and branches into Jira for the groups you specify,
configure Jira for DVCS. This import takes a few minutes and, after
it completes, refreshes every 60 minutes:

1. Complete the [GitLab configuration](#configure-a-gitlab-application-for-dvcs).
1. Go to your DVCS account:
   - **For Jira Server**, select **Settings (gear) > Applications > DVCS accounts**.
1. To create a new integration, for **Host**, select **GitLab** or **GitLab Self-Managed**.
1. For **Team or User Account**, enter the relative path of a top-level GitLab group that [the GitLab user](#configure-a-gitlab-application-for-dvcs) can access.
1. In the **Host URL** text box, enter the appropriate URL.
   Replace `<gitlab.example.com>` with your GitLab instance domain.
   Use `https://<gitlab.example.com>`.

1. For **Client ID**, use the [**Application ID** value](#configure-a-gitlab-application-for-dvcs).
1. For **Client Secret**, use the [**Secret** value](#configure-a-gitlab-application-for-dvcs).
1. Ensure that all other checkboxes are selected.
1. To create the DVCS account, select **Add** and then **Continue**.
1. Jira redirects to GitLab where you have to confirm the authorization.
   GitLab then redirects back to Jira where the synced
   projects should display in the new account.

To connect additional GitLab projects from other GitLab top-level groups or
personal namespaces, repeat the previous steps with additional Jira DVCS accounts.

For more information about how to use the integration, see [Jira development panel](../development_panel.md).

## Refresh data imported to Jira

Jira imports the commits and branches every 60 minutes for your projects. You
can refresh the data manually from the Jira interface:

1. Sign in to your Jira instance as the user you configured the integration with.
1. Go to **Settings (gear) > Applications**.
1. Select **DVCS accounts**.
1. In the table, for the repository you want to refresh, in the **Last Activity**
   column, select the icon.

## Migrate to the GitLab for Jira Cloud app

If you're using the Jira DVCS connector with Jira Cloud, migrate to the GitLab for Jira Cloud app.
For more information, see [Install the GitLab for Jira Cloud app](../connect-app.md#install-the-gitlab-for-jira-cloud-app).

### Feature comparison of DVCS and GitLab for Jira Cloud app

| Feature            | DVCS                   | GitLab for Jira Cloud app |
|---------------------|------------------------|---------------------------|
| Smart Commits       | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync merge requests | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync branches       | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync commits        | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync existing data  | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync builds         | **{dotted-circle}** No | **{check-circle}** Yes |
| Sync deployments    | **{dotted-circle}** No | **{check-circle}** Yes |
| Sync feature flags  | **{dotted-circle}** No | **{check-circle}** Yes |
| Sync interval       | 60 minutes             | Real time              |
| Create branches     | **{dotted-circle}** No | **{check-circle}** Yes (GitLab SaaS only) |
