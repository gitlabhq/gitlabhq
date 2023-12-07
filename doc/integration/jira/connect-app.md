---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab for Jira Cloud app **(FREE ALL)**

NOTE:
This page contains information about configuring the GitLab for Jira Cloud app on GitLab.com. For administrator documentation, see [GitLab for Jira Cloud app administration](../../administration/settings/jira_cloud_app.md).

With the [GitLab for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud) app, you can connect GitLab and Jira Cloud to sync development information in real time. You can view this information in the [Jira development panel](development_panel.md).

You can use the GitLab for Jira Cloud app to link top-level groups or subgroups. It's not possible to directly link projects or personal namespaces.

To set up the GitLab for Jira Cloud app on GitLab.com, [install the GitLab for Jira Cloud app](#install-the-gitlab-for-jira-cloud-app).
For Jira Data Center or Jira Server, use the [Jira DVCS connector](dvcs/index.md) developed and maintained by Atlassian.

## GitLab data synced to Jira

After you link a group, the following GitLab data is synced to Jira for all projects in that group when you [mention a Jira issue ID](development_panel.md#information-displayed-in-the-development-panel):

- Existing project data (before you linked the group):
  - The last 400 merge requests
  - The last 400 branches and the last commit to each of those branches (GitLab 15.11 and later)
- New project data (after you linked the group):
  - Merge requests
  - Branches
  - Commits
  - Builds
  - Deployments
  - Feature flags

## Install the GitLab for Jira Cloud app **(FREE SAAS)**

Prerequisites:

- You must have [site administrator](https://support.atlassian.com/user-management/docs/give-users-admin-permissions/#Make-someone-a-site-admin) access to the Jira instance.
- Your network must allow inbound and outbound connections between GitLab and Jira.

To install the GitLab for Jira Cloud app:

1. In Jira, on the top bar, select **Apps > Explore more apps** and search for `GitLab for Jira Cloud`.
1. Select **GitLab for Jira Cloud**, then select **Get it now**.

Alternatively, [get the app directly from the Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).

You can now [configure the GitLab for Jira Cloud app](#configure-the-gitlab-for-jira-cloud-app).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see
[Configure the GitLab for Jira Cloud app from the Atlassian Marketplace](https://youtu.be/SwR-g1s1zTo).

## Configure the GitLab for Jira Cloud app **(FREE SAAS)**

> **Add namespace** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/331432) to **Link groups** in GitLab 16.1.

Prerequisites:

- You must have at least the Maintainer role for the GitLab group.
- You must have [site administrator](https://support.atlassian.com/user-management/docs/give-users-admin-permissions/#Make-someone-a-site-admin) access to the Jira instance.

You can sync data from GitLab to Jira by linking the GitLab for Jira Cloud app to one or more GitLab groups.
To configure the GitLab for Jira Cloud app:

1. In Jira, on the top bar, select **Apps > Manage your apps**.
1. Expand **GitLab for Jira**.
1. Select **Get started**.
1. Optional. Select **Change GitLab version** to set the GitLab instance to use with Jira.
1. Select **Sign into GitLab**.
1. For a list of groups you can link to, select **Link groups**.
1. To link to a group, select **Link**.

After you link to a GitLab group, data is synced to Jira for all projects in that group.
The initial data sync happens in batches of 20 projects per minute.
For groups with many projects, the data sync for some projects is delayed.

## Update the GitLab for Jira Cloud app

Most updates to the app are automatic. For more information, see the
[Atlassian documentation](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/).

If the app requires additional permissions, [you must manually approve the update in Jira](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval).

## Security considerations

The GitLab for Jira Cloud app connects GitLab and Jira. Data must be shared between the two applications, and access must be granted in both directions.

### Access to Jira through access token

Jira shares an access token with GitLab to authenticate and authorize data pushes to Jira.
As part of the app installation process, Jira sends a handshake request to GitLab containing the access token.
The handshake is signed with an [asymmetric JWT](https://developer.atlassian.com/cloud/jira/platform/understanding-jwt-for-connect-apps/),
and the access token is stored encrypted with `AES256-GCM` on GitLab.

## Troubleshooting

When configuring the GitLab for Jira Cloud app on GitLab.com, you might encounter the following issues.

For self-managed GitLab, see [GitLab for Jira Cloud app administration](../../administration/settings/jira_cloud_app.md#troubleshooting).

### `Failed to link group`

After you connect the GitLab for Jira Cloud app, you might get this error:

```plaintext
Failed to link group. Please try again.
```

`403` status code is returned if the user information cannot be fetched from Jira due to insufficient permissions.

To resolve this issue, ensure that the Jira user that installs and configures the GitLab for Jira Cloud app meets certain
[requirements](../../administration/settings/jira_cloud_app.md#jira-user-requirements).
