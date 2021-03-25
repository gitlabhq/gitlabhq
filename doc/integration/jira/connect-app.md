---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab for Jira app **(FREE SAAS)**

You can integrate GitLab.com and Jira Cloud using the
[GitLab for Jira](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud)
app in the Atlassian Marketplace. The user configuring GitLab for Jira must have
[Maintainer](../../user/permissions.md) permissions in the GitLab namespace.

This method is recommended when using GitLab.com and Jira Cloud because data is synchronized in real-time. The DVCS connector updates data only once per hour. If you are not using both of these environments, use the [Jira DVCS Connector](dvcs.md) method.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a walkthrough of the integration with GitLab for Jira, watch [Configure GitLab Jira Integration using Marketplace App](https://youtu.be/SwR-g1s1zTo) on YouTube.

1. Go to **Jira Settings > Apps > Find new apps**, then search for GitLab.
1. Click **GitLab for Jira**, then click **Get it now**, or go to the
   [App in the marketplace directly](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud).

   ![Install GitLab App on Jira](img/jira_dev_panel_setup_com_1.png)
1. After installing, click **Get started** to go to the configurations page.
   This page is always available under **Jira Settings > Apps > Manage apps**.

   ![Start GitLab App configuration on Jira](img/jira_dev_panel_setup_com_2.png)
1. If not already signed in to GitLab.com, you must sign in as a user with
   [Maintainer](../../user/permissions.md) permissions to add namespaces.

   ![Sign in to GitLab.com in GitLab Jira App](img/jira_dev_panel_setup_com_3_v13_9.png)
1. Select **Add namespace** to open the list of available namespaces.

1. Identify the namespace you want to link, and select **Link**.

   ![Link namespace in GitLab Jira App](img/jira_dev_panel_setup_com_4_v13_9.png)

NOTE:
The GitLab user only needs access when adding a new namespace. For syncing with
Jira, we do not depend on the user's token.

After a namespace is added:

- All future commits, branches, and merge requests of all projects under that namespace
  are synced to Jira.
- From GitLab 13.8, past merge request data is synced to Jira.

Support for syncing past branch and commit data [is planned](https://gitlab.com/gitlab-org/gitlab/-/issues/263240).

For more information, see [Usage](index.md#usage).

## Troubleshooting GitLab for Jira

The GitLab for Jira App uses an iframe to add namespaces on the settings page. Some browsers block cross-site cookies. This can lead to a message saying that the user needs to log in on GitLab.com even though the user is already logged in.

> "You need to sign in or sign up before continuing."

In this case, use [Firefox](https://www.mozilla.org/en-US/firefox/) or enable cross-site cookies in your browser.
