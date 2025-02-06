---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Discord Notifications
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
1. Copy the URL from the **WEBHOOK URL** field.
1. Select **Save**.

## Configure created webhook in GitLab

> - Event webhook overrides [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125621) in GitLab 16.3.

With the webhook URL created in the Discord channel, you can set up the Discord Notifications integration in GitLab.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Discord Notifications**.
1. Ensure that the **Active** toggle is enabled.
1. Paste the webhook URL that you [created earlier](#create-webhook) into the **Webhook** field.
1. Select the checkboxes corresponding to the GitLab events for which you want to send notifications to Discord.
1. Optionally for each checkbox that you select, enter a new Discord webhook URL that you have [configured](#create-webhook)
   to override the default one in the **Webhook** field.
1. Configure the remaining options and select the **Save changes** button.

The Discord channel you created the webhook for now receives notification of the GitLab events that were configured.
