---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Discord notifications
description: "Configure the Discord notifications integration to receive notifications from GitLab in Discord channels."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The Discord Notifications integration sends event notifications from GitLab to the channel for which the webhook was created.

To send GitLab event notifications to a Discord channel, [create a webhook in Discord](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
and configure it in GitLab.

## Create webhook

1. Open the Discord channel you want to receive GitLab event notifications.
1. From the channel menu, select **Edit channel**.
1. Select **Integrations**.
1. If there are no existing webhooks, select **Create Webhook**. Otherwise, select **View Webhooks** then **New Webhook**.
1. Enter the name of the bot to post the message.
1. Optional. Edit the avatar.
1. Copy the URL from the **WEBHOOK URL** text box.
1. Select **Save**.

## Configure created webhook in GitLab

{{< history >}}

- Webhook URL validation introduced in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must use a Discord URL (`https://discord.com/api/webhooks/webhook-snowflake/webhook-token`).

With the webhook URL created in the Discord channel, you can set up the Discord Notifications integration in GitLab.

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select **Discord Notifications**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In the **Webhook** text box, paste the webhook URL you [created earlier](#create-webhook).
1. Select the checkboxes corresponding to the GitLab events for which you want to send notifications to Discord.
1. Optional. For each checkbox you select, enter another Discord webhook URL you have
   [configured](#create-webhook) to override the URL in the **Webhook** text box.
1. Configure the remaining options and select **Save changes**.

The Discord channel you created the webhook for now receives notification of the GitLab events that were configured.
