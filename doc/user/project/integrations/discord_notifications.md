---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Discord Notifications service **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22684) in GitLab 11.6.

The Discord Notifications service sends event notifications from GitLab to the channel for which the webhook was created.

To send GitLab event notifications to a Discord channel, [create a webhook in Discord](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
and configure it in GitLab.

## Create webhook

1. Open the Discord channel you want to receive GitLab event notifications.
1. From the channel menu, select **Edit channel**.
1. Click on **Webhooks** menu item.
1. Click the **Create Webhook** button and fill in the name of the bot to post the messages. Optionally, edit the avatar.
1. Note the URL from the **WEBHOOK URL** field.
1. Click the **Save** button.

## Configure created webhook in GitLab

With the webhook URL created in the Discord channel, you can set up the Discord Notifications service in GitLab.

1. Navigate to the [Integrations page](overview.md#accessing-integrations) in your project's settings. That is, **Project > Settings > Integrations**.
1. Select the **Discord Notifications** integration to configure it.
1. Ensure that the **Active** toggle is enabled.
1. Check the checkboxes corresponding to the GitLab events for which you want to send notifications to Discord.
1. Paste the webhook URL that you copied from the create Discord webhook step.
1. Configure the remaining options and click the **Save changes** button.

The Discord channel you created the webhook for now receives notification of the GitLab events that were configured.
