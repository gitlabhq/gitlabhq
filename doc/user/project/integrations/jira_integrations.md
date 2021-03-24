---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jira integrations **(FREE)**

GitLab can be integrated with [Jira](https://www.atlassian.com/software/jira).

[Issues](../issues/index.md) are a tool for discussing ideas, and planning and tracking work.
However, your organization may already use Jira for these purposes, with extensive, established data
and business processes they rely on.

Although you can [migrate](../../../user/project/import/jira.md) your Jira issues and work
exclusively in GitLab, you can also continue to use Jira by using the GitLab Jira integrations.

## Integration types

There are two different Jira integrations that allow different types of cross-referencing between
GitLab activity and Jira issues, with additional features:

- [Jira integration](jira.md), built in to GitLab. In a given GitLab project, it can be configured
  to connect to any Jira instance, either hosted by you or hosted in
  [Atlassian cloud](https://www.atlassian.com/cloud).
- [Jira development panel integration](../../../integration/jira/index.md). Connects all
  GitLab projects under a specified group or personal namespace.

Jira development panel integration configuration depends on whether you are
using Jira on [Atlassian cloud](https://www.atlassian.com/cloud) or on your own server:

- *If your Jira instance is hosted on Atlassian Cloud:*
  - **GitLab.com (SaaS) customers**: Use the
    [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview)
    application installed from the [Atlassian Marketplace](https://marketplace.atlassian.com).
  - **Self-managed installs**: Use the
    [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview), with
    [this workaround process](#install-the-gitlab-jira-cloud-application-for-self-managed-instances). Read the
    [relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/268278) for more information.
- *If your Jira instance is hosted on your own server:*
  Use the [Jira DVCS connector](../../../integration/jira/index.md).

### Install the GitLab Jira Cloud application for self-managed instances **(FREE SELF)**

If your GitLab instance is self-managed, you must follow some
extra steps to install the GitLab Jira Cloud application.

Each Jira Cloud application must be installed from a single location. Jira fetches
a [manifest file](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/)
from the location you provide. The manifest file describes the application to the system. To support
self-managed GitLab instances with Jira Cloud, you can either:

- [Install the application manually](#install-the-application-manually).
- [Create a Marketplace listing](#create-a-marketplace-listing).

#### Install the application manually **(FREE SELF)**

You can configure your Atlassian Cloud instance to allow you to install applications
from outside the Marketplace, which allows you to install the application:

1. Sign in to your Jira instance as a user with administrator permissions.
1. Place your Jira instance into
   [development mode](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-2--enable-development-mode).
1. Sign in to your GitLab application as a user with [Administrator](../../permissions.md) permissions.
1. Install the GitLab application from your self-managed GitLab instance, as
   described in the [Atlassian developer guides](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/#step-3--install-and-test-your-app)).
1. In your Jira instance, go to **Apps > Manage Apps** and click **Upload app**:

   ![Image showing button labeled "upload app"](jira-upload-app_v13_11.png)

1. For **App descriptor URL**, provide full URL to your manifest file, modifying this
   URL based on your instance configuration: `https://your.domain/your-path/-/jira_connect/app_descriptor.json`
1. Click **Upload**, and Jira fetches the content of your `app_descriptor` file and installs
   it for you.
1. If the upload is successful, Jira displays a modal panel: **Installed and ready to go!**
   Click **Get started** to configure the integration.

   ![Image showing success modal](jira-upload-app-success_v13_11.png)

The **GitLab for Jira** app now displays under **Manage apps**. You can also
click **Get started** to open the configuration page rendered from your GitLab instance.

NOTE:
If you make changes to the application descriptor, you must uninstall, then reinstall, the
application.

#### Create a Marketplace listing **(FREE SELF)**

If you prefer to not use development mode on your Jira instance, you can create
your own Marketplace listing for your instance, which enables your application
to be installed from the Atlassian Marketplace.

For full instructions, review the Atlassian [guide to creating a marketplace listing](https://developer.atlassian.com/platform/marketplace/installing-cloud-apps/#creating-the-marketplace-listing). To create a
Marketplace listing, you must:

1. Register as a Marketplace vendor.
1. List your application, using the application descriptor URL.
   - Your manifest file is located at: `https://your.domain/your-path/-/jira_connect/app_descriptor.json`
   - GitLab recommends you list your application as `private`, because public
     applications can be viewed and installed by any user.
1. Generate test license tokens for your application.

Review the
[official Atlassian documentation](https://developer.atlassian.com/platform/marketplace/installing-cloud-apps/#creating-the-marketplace-listing)
for details.

NOTE:
DVCS means distributed version control system.

## Feature comparison

The integration to use depends on the capabilities you require. You can install both at the same
time.

| Capability                                                                  | Jira integration                                                                                                                                              | Jira Development Panel integration                                                                                     |
|:----------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------|
| Mention of Jira issue ID in GitLab is automatically linked to that issue    | Yes                                                                                                                                                           | No                                                                                                                     |
| Mention of Jira issue ID in GitLab issue/MR is reflected in the Jira issue  | Yes, as a Jira comment with the GitLab issue/MR title and a link back to it. Its first mention also adds the GitLab page to the Jira issue under “Web links”. | Yes, in the issue's Development panel                                                                                  |
| Mention of Jira issue ID in GitLab commit message is reflected in the issue | Yes. The entire commit message is added to the Jira issue as a comment and under “Web links”, each with a link back to the commit in GitLab.                  | Yes, in the issue's Development panel and optionally with a custom comment on the Jira issue using Jira Smart Commits. |
| Mention of Jira issue ID in GitLab branch names is reflected in Jira issue  | No                                                                                                                                                            | Yes, in the issue's Development panel                                                                                  |
| Pipeline status is shown in Jira issue                                      | No                                                                                                                                                            | Yes, in the issue's Development panel when using Jira Cloud and the GitLab application.                                |
| Deployment status is shown in Jira issue                                    | No                                                                                                                                                            | Yes, in the issue's Development panel when using Jira Cloud and the GitLab application.                               |
| Record Jira time tracking information against an issue                      | No                                                                                                                                                            | Yes. Time can be specified via Jira Smart Commits.                                                                     |
| Transition or close a Jira issue with a Git commit or merge request         | Yes. Only a single transition type, typically configured to close the issue by setting it to Done.                                                            | Yes. Transition to any state using Jira Smart Commits.                                                                 |
| Display a list of Jira issues                                               | Yes **(PREMIUM)**                                                                                                                                             | No                                                                                                                     |
| Create a Jira issue from a vulnerability or finding **(ULTIMATE)**          | Yes                                                                                                                                                           | No                                                                                                                     |
