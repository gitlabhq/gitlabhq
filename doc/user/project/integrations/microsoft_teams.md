---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Microsoft Teams notifications
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can integrate Microsoft Teams notifications with GitLab and display notifications about GitLab projects
in Microsoft Teams. To integrate the services, you must:

1. [Configure Microsoft Teams](#configure-microsoft-teams) to enable a webhook
   to listen for changes.
1. [Configure your GitLab project](#configure-your-gitlab-project) to push notifications
   to the Microsoft Teams webhook.

## Configure Microsoft Teams

WARNING:
New Microsoft Teams integrations using Microsoft Connectors can no longer be created and
existing integrations must be transitioned to workflow apps by December 2025.
Microsoft [announced](https://devblogs.microsoft.com/microsoft365dev/retirement-of-office-365-connectors-within-microsoft-teams/) the retirement of Microsoft Teams integrations using Microsoft Connectors.

To configure Microsoft Teams to listen for notifications from GitLab:

1. In Microsoft Teams, find and select the workflow template "Post to a channel when a webhook request is received".

   ![Selecting a workflow webhook in Microsoft Teams](img/microsoft_teams_select_webhook_workflow_v17_4.png)

1. Enter a name for the webhook. The name is displayed next to every message that
   comes in through the webhook. Select **Next**.
1. Select the team and channel you want to add the integration to, then select **Add workflow**.
1. Copy the webhook URL, as you need it to configure GitLab.

## Configure your GitLab project

After you configure Microsoft Teams to receive notifications, you must configure
GitLab to send the notifications:

1. Sign in to GitLab as an administrator.
1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Microsoft Teams notifications**.
1. To enable the integration, select **Active**.
1. In the **Trigger** section, select the checkbox next to each event to enable it:
   - Push
   - Issue
   - Confidential issue
   - Merge request
   - Note
   - Confidential note
   - Tag push
   - Pipeline
   - Wiki page
1. In **Webhook**, paste the URL you copied when you
   [configured Microsoft Teams](#configure-microsoft-teams).
1. Optional. If you enable the pipeline trigger, select the
   **Notify only broken pipelines** checkbox to push notifications only when pipelines break.
1. Select the branches you want to send notifications for.
1. Select **Save changes**.

## Related topics

- [Setting up an incoming webhook on Microsoft Teams](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using#setting-up-a-custom-incoming-webhook)
