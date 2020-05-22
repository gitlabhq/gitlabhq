# Hangouts Chat service

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/43756) in GitLab 11.2.

The Hangouts Chat service sends notifications from GitLab to the room for which the webhook was created.

## On Hangouts Chat

1. Open the chat room in which you want to see the notifications.
1. From the chat room menu, select **Configure Webhooks**.
1. Click on **ADD WEBHOOK** and fill in the name of the bot that will post the messages. Optionally define avatar.
1. Click **SAVE** and copy the **Webhook URL** of your webhook.

See also [the Hangouts Chat documentation for configuring incoming webhooks](https://developers.google.com/hangouts/chat/how-tos/webhooks)

## On GitLab

When you have the **Webhook URL** for your Hangouts Chat room webhook, you can set up the GitLab service.

1. Navigate to the [Integrations page](overview.md#accessing-integrations) in your project's settings, i.e. **Project > Settings > Integrations**.
1. Select the **Hangouts Chat** integration to configure it.
1. Ensure that the **Active** toggle is enabled.
1. Check the checkboxes corresponding to the GitLab events you want to receive.
1. Paste the **Webhook URL** that you copied from the Hangouts Chat configuration step.
1. Configure the remaining options and click `Save changes`.

Your Hangouts Chat room will now start receiving GitLab event notifications as configured.

![Hangouts Chat configuration](img/hangouts_chat_configuration.png)
