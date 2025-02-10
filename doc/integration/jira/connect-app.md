---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab for Jira Cloud app
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

NOTE:
This page contains user documentation for the GitLab for Jira Cloud app. For administrator documentation, see [GitLab for Jira Cloud app administration](../../administration/settings/jira_cloud_app.md).

With the [GitLab for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud) app, you can connect GitLab and Jira Cloud to sync development information in real time. You can view this information in the [Jira development panel](development_panel.md).

You can use the GitLab for Jira Cloud app to link top-level groups or subgroups. It's not possible to directly link projects or personal namespaces.

To set up the GitLab for Jira Cloud app on GitLab.com, [install the GitLab for Jira Cloud app](#install-the-gitlab-for-jira-cloud-app).

After you set up the app, you can use the [project toolchain](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-connections-feature/)
developed and maintained by Atlassian to [link GitLab repositories to Jira projects](https://support.atlassian.com/jira-software-cloud/docs/link-repositories-to-a-project/#Link-repositories-using-the-toolchain-feature).
The project toolchain does not affect how development information is synced between GitLab and Jira Cloud.

For Jira Data Center or Jira Server, use the [Jira DVCS connector](dvcs/_index.md) developed and maintained by Atlassian.

## GitLab data synced to Jira

After you link a group, the following GitLab data is synced to Jira for all projects in that group when you [mention a Jira issue ID](development_panel.md#information-displayed-in-the-development-panel):

- Existing project data (before you linked the group):
  - The last 400 merge requests
  - The last 400 branches and the last commit to each of those branches (GitLab 15.11 and later)
- New project data (after you linked the group):
  - Merge requests
    - Merge request author
  - Branches
  - Commits
    - Commit author
  - Pipelines
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
[Installing the GitLab for Jira Cloud app from the Atlassian Marketplace for GitLab.com](https://youtu.be/52rB586_rs8?list=PL05JrBw4t0Koazgli_PmMQCER2pVH7vUT).
<!-- Video published on 2024-10-30 -->

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
1. Optional. To link GitLab Self-Managed with Jira, select **Change GitLab version**.
   1. Select all checkboxes, then select **Next**.
   1. Enter your **GitLab instance URL**, then select **Save**.
1. Select **Sign in to GitLab**.

   NOTE:
   [Enterprise users](../../user/enterprise_user/_index.md) with [disabled password authentication for their group](../../user/group/saml_sso/_index.md#disable-password-authentication-for-enterprise-users)
   must first sign in to GitLab with their group's single sign-on URL.

1. Select **Authorize**. A list of groups is now visible.
1. Select **Link groups**.
1. To link to a group, select **Link**.

<!-- markdownlint-enable MD044 -->

After you link to a GitLab group:

- Data is synced to Jira for all projects in that group. The initial data sync happens in batches of 20 projects per minute.
  For groups with many projects, the data sync for some projects is delayed.
- A GitLab for Jira Cloud app integration is automatically enabled for the group, and all subgroups or projects in that group.
  The integration allows you to [configure Jira Service Management](#configure-jira-service-management).

## Configure Jira Service Management

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460663) in GitLab 17.2 [with a flag](../../administration/feature_flags.md) named `enable_jira_connect_configuration`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/467117) in GitLab 17.4. Feature flag `enable_jira_connect_configuration` removed.

NOTE:
This feature was added as a community contribution and is developed and maintained by the GitLab community only.

Prerequisites:

- The GitLab for Jira Cloud app must be [installed](#install-the-gitlab-for-jira-cloud-app).
- A [GitLab group to be linked](#configure-the-gitlab-for-jira-cloud-app) in the GitLab for Jira Cloud app configuration.

You can connect GitLab to your IT service project to track your deployments.

Configuration happens in GitLab, in the GitLab for
Jira Cloud app integration. The integration is enabled for a group, its subgroups, and projects in GitLab after a [GitLab group has been linked](#configure-the-gitlab-for-jira-cloud-app).

Enabling and disabling the GitLab for Jira Cloud app integration happens entirely automatically through group linking,
and not through the GitLab integrations form or API.

In Jira Service Management:

1. In your service project, go to **Project settings > Change management**.
1. Select **Connect Pipeline > GitLab**, then copy the **Service ID** at the end of the setup flow.

In GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **GitLab for Jira Cloud app**. If the integration is disabled, first [link a GitLab group](#configure-the-gitlab-for-jira-cloud-app)
   which enables the GitLab for Jira Cloud app integration for the group, its subgroups, and projects.
1. In the **Service ID** field, enter the service ID that you want to map into this project. To use multiple service IDs,
   add a comma between each service ID.

You can map up to 100 services.

For more information about deployment tracking in Jira, see [Set up deployment tracking](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-tracking/).

### Set up deployment gating with GitLab

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/473774) in GitLab 17.6.

NOTE:
This feature was added as a community contribution and is developed and maintained by the GitLab community only.

You can set up deployment gating to bring change requests from GitLab to Jira Service Management for approval.
With deployment gating, any GitLab deployments to your selected environments are automatically sent
to Jira Service Management and are only deployed if they're approved.

#### Create the service account token

To create a service account token in GitLab, you must first create a personal access token.
This token authenticates the service account token used to manage GitLab deployments in Jira Service Management.

To create the service account token:

1. [Create a service account user](../../api/user_service_accounts.md#create-a-service-account-user).
1. [Add the service account to a group or project](../../api/members.md#add-a-member-to-a-group-or-project)
   by using your personal access token.
1. [Add the service account to protected environments](../../ci/environments/protected_environments.md#protecting-environments).
1. [Generate a service account token](../../api/group_service_accounts.md#create-a-personal-access-token-for-a-service-account-user)
   by using your personal access token.
1. Copy the service account token value.

#### Enable deployment gating

To enable deployment gating:

- In GitLab:

  1. On the left sidebar, select **Search or go to** and find your project.
  1. Select **Settings > Integrations**.
  1. Select **GitLab for Jira Cloud app**.
  1. Under **Deployment gating**, select the **Enable deployment gating** checkbox.
  1. In the **Environment tiers** text box, enter the names of the environments you want to enable deployment gating for.
     You can enter multiple environment names separated by commas (for example, `production, staging, testing, development`).
     Use lowercase letters only.
  1. Select **Save changes**.

- In Jira Service Management:

  1. [Set up deployment gating](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-gating/).
  1. In the **Service account token** text box, [paste the service account token value you copied from GitLab](#create-the-service-account-token).

#### Add the service account to protected environments

To add the service account to your protected environments in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Protected environments** and select **Protect an environment**.
1. From the **Select environment** dropdown list, select an environment to protect (for example, **staging**).
1. From the **Allowed to deploy** dropdown list, select who can deploy to this environment (for example, **Developers + Maintainers**).
1. From the **Approvers** dropdown list, select the [service account you created](#create-the-service-account-token).
1. Select **Protect**.

#### Example API requests

- Create a service account user:

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=<name_of_your_choice>&username=<username_of_your_choice>"  "<https://gitlab.com/api/v4/groups/<group_id>/service_accounts"
  ```

- Add the service account to a group or project by using your personal access token:

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/groups/<group_id>/members"
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/projects/<project_id>/members"
  ```

- Generate a service account token by using your personal access token:

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"
  "https://gitlab.com/api/v4/groups/<group_id>/service_accounts/<service_account_id>/personal_access_tokens" --data "scopes[]=api,read_user,read_repository" --data "name=service_accounts_token"
  ```

## Update the GitLab for Jira Cloud app

Most updates to the app are automatic. For more information, see the
[Atlassian documentation](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/).

If the app requires additional permissions, [you must manually approve the update in Jira](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval).

## Security considerations

The GitLab for Jira Cloud app connects GitLab and Jira. Data must be shared between the two applications, and access must be granted in both directions.

### GitLab access to Jira

When you [configure the GitLab for Jira Cloud app](#configure-the-gitlab-for-jira-cloud-app), GitLab receives a **shared secret token** from Jira.
The token grants GitLab `READ`, `WRITE`, and `DELETE` [app scopes](https://developer.atlassian.com/cloud/jira/software/scopes-for-connect-apps/#scopes-for-atlassian-connect-apps) for the Jira project.
These scopes are required to update information in the Jira project's development panel.
The token does not grant GitLab access to any other Atlassian product besides the Jira project the app was installed in.

The token is encrypted with `AES256-GCM` and stored on GitLab.
When the GitLab for Jira Cloud app is uninstalled from your Jira project, GitLab deletes the token.

### Jira access to GitLab

Jira does not gain any access to GitLab.

### Data sent from GitLab to Jira

For all the data sent to Jira, see [GitLab data synced to Jira](#gitlab-data-synced-to-jira).

For more information about the specific data properties sent to Jira, see the [serializer classes](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/atlassian/jira_connect/serializers) involved in data synchronization.

### Data sent from Jira to GitLab

GitLab receives a [lifecycle event](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/#lifecycle) from Jira when the GitLab for Jira Cloud app is installed or uninstalled.
The event includes a [token](#gitlab-access-to-jira) to verify subsequent lifecycle events and to authenticate when [sending data to Jira](#data-sent-from-gitlab-to-jira).
Lifecycle event requests from Jira are [verified](https://developer.atlassian.com/cloud/jira/platform/security-for-connect-apps/#validating-installation-lifecycle-requests).

For GitLab Self-Managed instances that use the GitLab for Jira Cloud app from the Atlassian Marketplace, GitLab.com handles lifecycle events and forwards them to the GitLab Self-Managed instance. For more information, see [GitLab.com handling of app lifecycle events](../../administration/settings/jira_cloud_app.md#gitlabcom-handling-of-app-lifecycle-events).

### Data stored by Jira

[Data sent to Jira](#data-sent-from-gitlab-to-jira) is stored by Jira
and displayed in the [Jira development panel](development_panel.md).

When the GitLab for Jira Cloud app is uninstalled, Jira permanently deletes this data.
This process happens asynchronously and might take up to several hours.

### Privacy and security details in the Atlassian Marketplace

For more information, see the [privacy and security details of the Atlassian Marketplace listing](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira-cloud?tab=privacy-and-security&hosting=cloud).

## Troubleshooting

When working with the GitLab for Jira Cloud app, you might encounter the following issues.

For administrator documentation, see [GitLab for Jira Cloud app administration](../../administration/settings/jira_cloud_app_troubleshooting.md).

### Error: `Failed to link group`

When you connect the GitLab for Jira Cloud app, you might get this error:

```plaintext
Failed to link group. Please try again.
```

A `403 Forbidden` is returned if the user information cannot be fetched from Jira because of insufficient permissions.

To resolve this issue, ensure you meet certain
[Jira user requirements](../../administration/settings/jira_cloud_app.md#jira-user-requirements).
