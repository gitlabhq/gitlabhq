---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira DVCS connector **(FREE)**

WARNING:
The Jira DVCS connector for Jira Cloud was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/362168) in GitLab 15.1
and is planned for removal in 16.0. Use the [GitLab for Jira Cloud app](../connect-app.md) instead.
The Jira DVCS connector was also deprecated for Jira 8.13 and earlier. You can only use the Jira DVCS connector with Jira Data Center or Jira Server in Jira 8.14 and later. Upgrade your Jira instance to Jira 8.14 or later, and reconfigure the Jira integration in your GitLab instance.

Use the Jira DVCS (distributed version control system) connector if you self-host
your Jira instance with Jira Data Center or Jira Server and want to use the [Jira development panel](../development_panel.md).

If you're on Jira Cloud, migrate to the GitLab for Jira Cloud app. For more information, see [Install the GitLab for Jira Cloud app](../connect-app.md#install-the-gitlab-for-jira-cloud-app).

## Configure the Jira DVCS connector

### Prerequisites

- Your GitLab instance must be accessible by Jira.
- You must have at least the Maintainer role for the GitLab group.
- Your network must allow inbound and outbound connections between GitLab and Jira.

### Create a GitLab application for DVCS

- **For projects in a single group**, you should create a [group application](../../oauth_provider.md#create-a-group-owned-application).
- **For projects across multiple groups**, you should create a separate GitLab user account for Jira integration work only.
  This account ensures regular maintenance does not affect your integration.
- **If you cannot create a group application or separate user account**, you can create instead:
  - [An instance-wide application](../../oauth_provider.md#create-an-instance-wide-application)
  - [A user-owned application](../../oauth_provider.md#create-a-user-owned-application)

To create a GitLab application for DVCS:

1. Go to the [appropriate **Applications** section](../../oauth_provider.md).
1. In the **Name** text box, enter a descriptive name for the integration (for example, `Jira`).
1. In the **Redirect URI** text box, enter the generated **Redirect URL** from
   [linking GitLab accounts](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html).
1. In **Scopes**, select `api` and clear any other checkboxes.
   The Jira DVCS connector requires a **write-enabled** `api` scope to automatically create and manage required webhooks.
1. Select **Submit**.
1. Copy the **Application ID** and **Secret** values.
   You need these values to configure Jira.

### Configure Jira for DVCS

To configure Jira for DVCS:

1. Go to your DVCS account. **For Jira Server**, select **Settings (gear) > Applications > DVCS accounts**.
1. To create a new integration, for **Host**, select **GitLab** or **GitLab Self-Managed**.
1. For **Team or User Account**, enter the relative path of a top-level GitLab group that [the GitLab user](#create-a-gitlab-application-for-dvcs) can access.
1. In the **Host URL** text box, enter the appropriate URL.
   Replace `<gitlab.example.com>` with your GitLab instance domain.
   Use `https://<gitlab.example.com>`.
1. For **Client ID**, use the [**Application ID** value](#create-a-gitlab-application-for-dvcs).
1. For **Client Secret**, use the [**Secret** value](#create-a-gitlab-application-for-dvcs).
1. Ensure that all other checkboxes are selected.
1. To create the DVCS account, select **Add** and then **Continue**.
1. Jira redirects to GitLab where you have to confirm the authorization.
   GitLab then redirects back to Jira where the synced
   projects should display in the new account. The initial sync takes a few minutes.

After the initial sync, it can take up to 60 minutes to refresh.

To connect additional GitLab projects from other GitLab top-level groups or
personal namespaces, repeat the previous steps with additional Jira DVCS accounts.

## Refresh data imported to Jira

Jira imports the commits and branches every 60 minutes for your projects. You
can refresh the data manually from the Jira interface:

1. Sign in to your Jira instance as the user you configured the integration with.
1. Go to **Settings (gear) > Applications**.
1. Select **DVCS accounts**.
1. In the table, for the repository you want to refresh, in the **Last Activity**
   column, select the icon.

## Troubleshooting

To troubleshoot the Jira development panel on your own server, see the
[Atlassian documentation](https://confluence.atlassian.com/jirakb/troubleshoot-the-development-panel-in-jira-server-574685212.html).
