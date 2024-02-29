---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Google Chat

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can configure your project in GitLab to send notifications to a
space of your choice in [Google Chat](https://chat.google.com/).

In GitLab 16.10 and later, threaded notifications are enabled by default
in Google Chat for the same GitLab object (for example, an issue or merge request).
For more information, see [issue 438452](https://gitlab.com/gitlab-org/gitlab/-/issues/438452).

## Enable the integration in Google Chat

To enable the integration in Google Chat:

1. Enter the space where you want to receive notifications from GitLab.
1. In the upper-left corner, from the space dropdown list, select **Apps & integrations**.
1. In the **Webhooks** section, select **Add webhooks**.
1. Enter the name for your webhook (for example, `GitLab integration`).
1. Optional. Add an avatar for your bot.
1. Select **Save**.
1. Copy the webhook URL.

For more information, see the
[Google Chat documentation for webhooks](https://developers.google.com/chat/how-tos/webhooks).

## Enable the integration in GitLab

To enable the integration in GitLab:

1. In your project, go to **Settings > Integrations** and select **Google Chat**.
1. Scroll down to the end of the page where you find a **Webhook** field.
1. Enter the webhook URL you copied from Google Chat.
1. Select the events you want to be notified about in your Google Chat space.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

To test the integration, make a change based on the events you selected and
see the notification in your Google Chat space.
