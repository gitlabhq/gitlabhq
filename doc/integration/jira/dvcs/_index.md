---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira DVCS connector
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use the Jira DVCS (distributed version control system) connector if you self-host your Jira instance
with Jira Data Center or Jira Server and want to use the [Jira development panel](../development_panel.md).
The Jira DVCS connector is developed and maintained by Atlassian.

To configure the Jira DVCS connector, see
[integrating with development tools using DVCS](https://confluence.atlassian.com/adminjiraserver/integrating-with-development-tools-using-dvcs-1047552689.html).
You can only use the Jira DVCS connector with Jira Data Center or Jira Server in Jira 8.14 and later.

Jira creates a webhook in the GitLab project to provide real-time updates.
To configure this webhook, you must have at least the Maintainer role for the project.
For more information, see [configuring webhook security](https://confluence.atlassian.com/adminjiraserver/configuring-webhook-security-1299913153.html).

The Jira DVCS connector for Jira Cloud was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118126) in GitLab 16.0.
Use the [GitLab for Jira Cloud app](../connect-app.md) instead.
For more information, see [Install the GitLab for Jira Cloud app](../connect-app.md#install-the-gitlab-for-jira-cloud-app).

## Refresh data imported to Jira

By default, Jira imports commits and branches for GitLab projects every 60 minutes.
To refresh the data manually in Jira:

1. Sign in to your Jira instance as the user you configured the integration with.
1. On the top bar, in the upper-right corner,
   select **Administration** ({{< icon name="settings" >}}) > **Applications**.
1. On the left sidebar, select **DVCS accounts**.
1. To refresh one or more repositories in a DVCS account:
   - **For all repositories**, next to the account,
     select the ellipsis ({{< icon name="ellipsis_h" >}}) > **Refresh repositories**.
   - **For a single repository**:
     1. Select the account.
     1. Hover over the repository you want to refresh, and in the **Last activity** column,
        select **Click to sync repository** ({{< icon name="retry" >}}).
