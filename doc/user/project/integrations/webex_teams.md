---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Webex Teams
description: "Send event notifications from GitLab to Webex Teams spaces with webhooks."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can configure GitLab to send notifications to a Webex Teams space:

1. Create a webhook for the space.
1. Add the webhook to GitLab.

## Create a webhook for the space

1. Go to the [Incoming Webhooks app page](https://apphub.webex.com/applications/incoming-webhooks-cisco-systems-38054-23307-75252).
1. Select **Connect**, and sign in to Webex Teams if required.
1. Enter a name for the webhook and select the space to receive the notifications.
1. Select **ADD**.
1. Copy the **Webhook URL**.

## Configure settings in GitLab

After you have a webhook URL for your Webex Teams space, you can configure GitLab to send
notifications:

1. To enable integration:
   - At the project or group level:
     1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
     1. Select **Settings** > **Integrations**.
   - At the instance level:
     1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
     1. Select **Settings** > **Integrations**.
1. Select the **Webex Teams** integration.
1. Ensure that the **Active** toggle is enabled.
1. Select the checkboxes corresponding to the GitLab events you want to receive in Webex Teams.
1. Paste the **Webhook** URL for the Webex Teams space.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

The Webex Teams space begins to receive all applicable GitLab events.
