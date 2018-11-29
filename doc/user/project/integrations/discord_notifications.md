# Discord Notifications service

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22684) in GitLab 11.6.

The Discord Notifications service sends event notifications from GitLab to the channel for which the webhook was created.

To send GitLab event notifications to a Discord channel, create a webhook in Discord and configure it in GitLab.

## Create webhook

1. Open the Discord channel you want to receive GitLab event notifications.
1. From the channel menu, select **Edit channel**.
1. Click on **Webhooks** menu item.
1. Click the **Create Webhook** button and fill in the name of the bot that will post the messages. Optionally, edit the avatar.
1. Note the URL from the **WEBHOOK URL** field.
1. Click the **Save** button.

## Configure created webhook in GitLab

With the webhook URL created in the Discord channel, you can set up the Discord Notifications service in GitLab.

1. Navigate to the [Integrations page](project_services.md#accessing-the-project-services) in your project's settings. That is, **Project > Settings > Integrations**.
1. Select the **Discord Notifications** project service to configure it.
1. Check the **Active** checkbox to turn on the service.
1. Check the checkboxes corresponding to the GitLab events for which you want to send notifications to Discord.
1. Paste the webhook URL that you copied from the create Discord webhook step.
1. Configure the remaining options and click the **Save changes** button.

The Discord channel you created the webhook for will now receive notification of the GitLab events that were configured.
