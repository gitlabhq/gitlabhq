---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Microsoft Teams notifications
description: "Configure the Microsoft Teams integration to receive notifications from GitLab in Microsoft Teams."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can integrate Microsoft Teams notifications with GitLab and display notifications about GitLab projects
in Microsoft Teams. To integrate the services, you must:

1. [Configure Microsoft Teams](#configure-microsoft-teams) to enable a webhook
   to listen for changes.
1. [Configure your GitLab project](#configure-your-gitlab-project) to push notifications
   to the Microsoft Teams webhook.

## Configure Microsoft Teams

> [!warning]
> Microsoft [announced](https://devblogs.microsoft.com/microsoft365dev/retirement-of-office-365-connectors-within-microsoft-teams/) the retirement of Office 365 Connectors in Microsoft Teams.
> New integrations must use Power Automate workflows. Existing connector-based integrations must be transitioned by December 2025.

To configure Microsoft Teams to receive notifications from GitLab, you must have
a workflow that accepts the GitLab webhook payload and posts messages
to your channel. You can create a:

- Power Automate workflow using a template.
- Custom workflow.

### Create a Power Automate workflow

1. In Microsoft Teams, next to the chat you want to receive notifications in,
   select **More chat options** ({{< icon name="ellipsis_h" >}}).
1. Select **Workflows**.
1. Search for and select the **Send webhook alerts to a channel** workflow template.
1. Under **Parameters**, enter the team and channel, and select **Save**.
1. After the workflow is created, on the Workflows dialog, select
   **Copy webhook link**.
1. Copy the webhook URL provided. You use this webhook URL to configure GitLab.
1. Close the Workflows dialog.

#### Modify the workflow to accept GitLab payloads

The default workflow template expects the Adaptive Card format, but GitLab sends
the Office 365 Connector Card format. To modify the workflow:

1. Go to Power Automate and sign in with your Microsoft account.
1. Select **My flows** and find the workflow you created.
1. Select **Edit** to modify the workflow.
1. Select the existing **Post card in a chat or channel** action and delete it.
1. Select **Add an action** and search for **Post message in a chat or channel**.
1. Configure the action:
   - **Post as**: Flow bot
   - **Post in**: Channel
   - **Team**: Select your team
   - **Channel**: Select your channel
   - **Message**: On the right of the text box, select **Insert expression**
     and enter `triggerOutputs()?['body']?['attachments'][0]?['content']`.
     Select **Add**.
1. Select **Save**.

### Create a custom workflow

For more control over the message format, create a custom workflow:

1. Go to Power Automate, and select **Create** > **Instant cloud flow**.
1. Name your workflow and select **When an HTTP request is received** as the trigger,
   then select **Create**.
1. Select **Add an action** and search for **Post message in a chat or channel** (Microsoft Teams).
1. In the trigger configuration, leave the JSON schema empty to accept any payload.
1. Configure the action:
   - **Post as**: Flow bot
   - **Post in**: Channel
   - **Team**: Select your team
   - **Channel**: Select your channel
   - **Message**: On the right of the text box, select **Insert expression**
     and enter `triggerOutputs()?['body']?['attachments'][0]?['content']`.
     Select **Add**.
1. Select **Save**.
1. In the workflow, select the **manual** trigger. Copy the **HTTP URL** from the trigger.
   You use this URL to configure GitLab.

## Configure your GitLab project

After you configure Microsoft Teams to receive notifications, you must configure
GitLab to send the notifications:

1. Sign in to GitLab as an administrator.
1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **Integrations**.
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
1. In **Webhook**, paste the URL you copied when you created a Power Automate or
   custom workflow.
1. Optional. If you enable the pipeline trigger, select the
   **Notify only broken pipelines** checkbox to push notifications only when pipelines break.
1. Optional. If you enable the pipeline trigger, select the
   **Notify only when status changes** checkbox to send notifications only when the pipeline status for the ref changes.
1. Select the branches you want to send notifications for.
1. Select **Save changes**.

## Related topics

- [Microsoft Power Automate documentation](https://learn.microsoft.com/en-us/power-automate/)
- [Microsoft Teams create incoming webhooks documentation](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)
