---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira DVCS connector
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
The Jira DVCS connector for Jira Cloud was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/362168)
in GitLab 15.1 and [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118126) in 16.0.
Use the [GitLab for Jira Cloud app](../connect-app.md) instead.
The Jira DVCS connector was also deprecated and removed for Jira 8.13 and earlier.
You can only use the Jira DVCS connector with Jira Data Center or Jira Server in Jira 8.14 and later.
Upgrade your Jira instance to Jira 8.14 or later and reconfigure the Jira issues integration on your GitLab instance.

Use the Jira DVCS (distributed version control system) connector if you self-host your Jira instance
with Jira Data Center or Jira Server and want to use the [Jira development panel](../development_panel.md).
The Jira DVCS connector is developed and maintained by Atlassian.

To configure the Jira DVCS connector, see the
[Atlassian documentation](https://confluence.atlassian.com/adminjiraserver/integrating-with-development-tools-using-dvcs-1047552689.html).

If you're on Jira Cloud, migrate to the GitLab for Jira Cloud app.
For more information, see [Install the GitLab for Jira Cloud app](../connect-app.md#install-the-gitlab-for-jira-cloud-app).

## Refresh data imported to Jira

Jira imports commits and branches for GitLab projects every 60 minutes.
To refresh the data manually in Jira:

1. Sign in to your Jira instance as the user you configured the integration with.
1. On the top bar, in the upper-right corner,
   select **Administration** (**{settings}**) > **Applications**.
1. On the left sidebar, select **DVCS accounts**.
1. To refresh one or more repositories in a DVCS account:
   - **For all repositories**, next to the account,
     select the ellipsis (**{ellipsis_h}**) > **Refresh repositories**.
   - **For a single repository**:
     1. Select the account.
     1. Hover over the repository you want to refresh, and in the **Last activity** column,
        select **Click to sync repository** (**{retry}**).
