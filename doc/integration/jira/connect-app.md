---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab for Jira Cloud app

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

NOTE:
This page contains user documentation for the GitLab for Jira Cloud app. For administrator documentation, see [GitLab for Jira Cloud app administration](../../administration/settings/jira_cloud_app.md).

With the [GitLab for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud) app, you can connect GitLab and Jira Cloud to sync development information in real time. You can view this information in the [Jira development panel](development_panel.md).

You can use the GitLab for Jira Cloud app to link top-level groups or subgroups. It's not possible to directly link projects or personal namespaces.

To set up the GitLab for Jira Cloud app on GitLab.com, [install the GitLab for Jira Cloud app](#install-the-gitlab-for-jira-cloud-app).

After you set up the app, you can use the [project toolchain](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-project-toolchain-in-jira/)
developed and maintained by Atlassian to [link GitLab repositories to Jira projects](https://support.atlassian.com/jira-software-cloud/docs/link-repositories-to-a-project/#Link-repositories-using-the-toolchain-feature).
The project toolchain does not affect how development information is synced between GitLab and Jira Cloud.

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

## Install the GitLab for Jira Cloud app

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

Prerequisites:

- Your network must allow inbound and outbound connections between GitLab and Jira.
- You must meet certain [Jira user requirements](../../administration/settings/jira_cloud_app.md#jira-user-requirements).

To install the GitLab for Jira Cloud app:

1. In Jira, on the top bar, select **Apps > Explore more apps** and search for `GitLab for Jira Cloud`.
1. Select **GitLab for Jira Cloud**, then select **Get it now**.

Alternatively, [get the app directly from the Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).

You can now [configure the GitLab for Jira Cloud app](#configure-the-gitlab-for-jira-cloud-app).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see
[Configure the GitLab for Jira Cloud app from the Atlassian Marketplace](https://youtu.be/SwR-g1s1zTo).

## Configure the GitLab for Jira Cloud app

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - **Add namespace** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/331432) to **Link groups** in GitLab 16.1.

Prerequisites:

- You must have at least the Maintainer role for the GitLab group.
- You must meet certain [Jira user requirements](../../administration/settings/jira_cloud_app.md#jira-user-requirements).

You can sync data from GitLab to Jira by linking the GitLab for Jira Cloud app to one or more GitLab groups.
To configure the GitLab for Jira Cloud app:

<!-- markdownlint-disable MD044 -->

1. In Jira, on the top bar, select **Apps > Manage your apps**.
1. Expand **GitLab for Jira**. Depending on how you installed the app, the name of the app is:
   - **GitLab for Jira (gitlab.com)** if you [installed the app from the Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).
   - **GitLab for Jira (`<gitlab.example.com>`)** if you [installed the app manually](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually).
1. Select **Get started**.
1. Optional. To link a self-managed GitLab instance with Jira, select **Change GitLab version**.
   1. Select all checkboxes, then select **Next**.
   1. Enter your **GitLab instance URL**, then select **Save**.
1. Select **Sign in to GitLab**, then enter your credentials.
1. Select **Authorize**. A list of groups is now visible.
1. Select **Link groups**.
1. To link to a group, select **Link**.

<!-- markdownlint-enable MD044 -->

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

When working with the GitLab for Jira Cloud app, you might encounter the following issues.

For administrator documentation, see [GitLab for Jira Cloud app administration](../../administration/settings/jira_cloud_app_troubleshooting.md).

### Error when connecting the app

When you connect the GitLab for Jira Cloud app, you might get this error:

```plaintext
Failed to link group. Please try again.
```

A `403 Forbidden` is returned if the user information cannot be fetched from Jira because of insufficient permissions.

To resolve this issue, ensure you meet certain
[Jira user requirements](../../administration/settings/jira_cloud_app.md#jira-user-requirements).
