---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira DVCS connector

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

WARNING:
The Jira DVCS connector for Jira Cloud was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/362168) in GitLab 15.1
and [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118126) in 16.0. Use the [GitLab for Jira Cloud app](../connect-app.md) instead.
The Jira DVCS connector was also deprecated and removed for Jira 8.13 and earlier. You can only use the Jira DVCS connector with Jira Data Center or Jira Server in Jira 8.14 and later. Upgrade your Jira instance to Jira 8.14 or later and reconfigure the Jira integration on your GitLab instance.

Use the Jira DVCS (distributed version control system) connector if you self-host
your Jira instance with Jira Data Center or Jira Server and want to use the [Jira development panel](../development_panel.md).
The Jira DVCS connector is developed and maintained by Atlassian. For more information, see the
[Atlassian documentation](https://confluence.atlassian.com/adminjiraserver/integrating-with-development-tools-using-dvcs-1047552689.html).

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

1. On the top bar, in the upper-right corner, select **Administration** (**{settings}**) > **Applications**.
1. On the left sidebar, select **DVCS accounts**.
1. From the **Host** dropdown list, select **GitLab** or **GitLab Self-Managed**.
1. For **Team or User Account**, enter the relative path of a [top-level GitLab group](#create-a-gitlab-application-for-dvcs) the GitLab user can access.
1. For **Host URL**, enter the domain of your GitLab instance.
1. From the **Client Configuration** dropdown list, select the [application link](#create-a-gitlab-application-for-dvcs) you've created.
1. Optional. Select or clear the **Auto Link New Repositories** and **Enable Smart Commits** checkboxes.
1. Select **Add**, then **Continue**.

Jira redirects to GitLab where you have to confirm the authorization. GitLab then redirects back to Jira
where the synced projects are displayed in the new account. The initial sync takes a few minutes.
After the initial sync, it can take up to 60 minutes to refresh.

To connect additional GitLab projects from other GitLab top-level groups or
personal namespaces, repeat the previous steps with additional Jira DVCS accounts.

## Refresh data imported to Jira

Jira imports commits and branches for GitLab projects every 60 minutes. To refresh the data manually in Jira:

1. Sign in to your Jira instance as the user you configured the integration with.
1. On the top bar, in the upper-right corner, select **Administration** (**{settings}**) > **Applications**.
1. On the left sidebar, select **DVCS accounts**.
1. To refresh one or more repositories in a DVCS account:
   - **For all repositories**, next to the account, select the ellipsis (**{ellipsis_h}**) > **Refresh repositories**.
   - **For a single repository**:
     1. Select the account.
     1. Hover over the repository you want to refresh, and in the **Last activity** column, select **Click to sync repository** (**{retry}**).
