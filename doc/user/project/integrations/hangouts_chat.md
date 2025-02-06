---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Chat
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can configure your project in GitLab to send notifications to a
space of your choice in [Google Chat](https://chat.google.com/).

In GitLab 16.10 and later, threaded notifications are enabled by default
in Google Chat for the same GitLab object (for example, an issue or merge request).
For more information, see [issue 438452](https://gitlab.com/gitlab-org/gitlab/-/issues/438452).

## Configure the integration

### In Google Chat

To configure the integration in Google Chat:

1. Go to the space where you want to receive notifications from GitLab.
1. In the upper left, next to the space name, select the down arrow (**{chevron-down}**) > **Apps & integrations**.
1. In the **Webhooks** section, select **Add webhooks**.
1. On the **Incoming webhooks** dialog:
   - In **Name**, enter a name for your webhook (for example, `GitLab integration`).
   - Optional. In **Avatar URL**, enter an avatar for your bot.
1. Select **Save**.
1. Next to the webhook URL, select the vertical ellipsis (**{ellipsis_v}**) > **Copy link**.

For more information about webhooks, see the
[Google Chat documentation](https://developers.google.com/workspace/chat/quickstart/webhooks).

### In GitLab

To configure the integration in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Google Chat**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **Webhook**, [paste the URL you copied from Google Chat](#in-google-chat).
1. In the **Trigger** section, select the checkbox for each GitLab event
   you want to receive notifications for in your Google Chat space.
1. Optional. In the **Notification settings** section:
   - Select the **Notify only broken pipelines** checkbox
     to receive notifications for failed pipelines only.
   - From the **Branches for which notifications are to be sent** dropdown list,
     select the branches you want to receive notifications for.
1. Optional. Select **Test settings**.
1. Select **Save changes**.
