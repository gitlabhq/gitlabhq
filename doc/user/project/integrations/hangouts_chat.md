---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Google Chat **(FREE)**

You can configure your project to send notifications from GitLab to a
room of your choice in [Google Chat](https://chat.google.com/) (formerly Google
Hangouts).

## Integration workflow

To enable this integration, first you need to create a webhook for the room in
Google Chat where you want to receive the notifications from your project.

After that, enable the integration in GitLab and choose the events you want to
be notified about in your Google Chat room.

For every selected event in your project, GitLab acts like a bot sending
notifications to Google Chat:

![Google Chat integration illustration](img/google_chat_integration_v13_11.png)

## Enable the integration in Google Chat

To enable the integration in Google Chat:

1. Enter the room where you want to receive notifications from GitLab.
1. In the upper-left corner, from the room dropdown list, select **Manage webhooks**.
1. Enter the name for your webhook, for example "GitLab integration".
1. Optional. Add an avatar for your bot.
1. Select **Save**.
1. Copy the webhook URL.

For further details, see [the Google Chat documentation for configuring webhooks](https://developers.google.com/chat/how-tos/webhooks).

### Enable threads in Google Chat

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27823) in GitLab 15.4.

To enable threaded notifications for the same GitLab object (for example, an issue or merge request):

1. Go to [Google Chat](https://chat.google.com/).
1. In **Spaces**, select **+ > Create space**.
1. Enter the space name and (optionally) other details, and select **Use threaded replies**.
1. Select **Create**.

You cannot enable threaded replies for existing Google Chat spaces.

## Enable the integration in GitLab

To enable the integration in GitLab:

1. In your project, go to **Settings > Integrations** and select **Google Chat**.
1. Scroll down to the end of the page where you find a **Webhook** field.
1. Enter the webhook URL you copied from Google Chat.
1. Select the events you want to be notified about in your Google Chat room.
1. Optional. Select **Test settings** to verify the connection.
1. Select **Save changes**.

To test the integration, make a change based on the events you selected and
see the notification in your Google Chat room.
