---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mattermost notifications
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the Mattermost notifications integration to send notifications for GitLab events
(for example, `issue created`) to Mattermost. You must configure both [Mattermost](#configure-mattermost-to-receive-gitlab-notifications)
and [GitLab](#configure-gitlab-to-send-notifications-to-mattermost).

You can also use [Mattermost slash commands](mattermost_slash_commands.md) to control
GitLab inside Mattermost.

## Configure Mattermost to receive GitLab notifications

To use the Mattermost integration you must create an incoming webhook integration
in Mattermost:

1. Sign in to your Mattermost instance.
1. [Enable incoming webhooks](https://docs.mattermost.com/configure/integrations-configuration-settings.html#enable-incoming-webhooks).
1. [Add an incoming webhook](https://developers.mattermost.com/integrate/webhooks/incoming/#create-an-incoming-webhook).
1. Choose a display name, description and channel, those can be overridden on GitLab.
1. Save it and copy the **Webhook URL** because we need this later for GitLab.

Incoming Webhooks might be blocked on your Mattermost instance. Ask your Mattermost administrator
to enable it on:

- **Mattermost System Console > Integrations > Integration Management** in Mattermost
  versions 5.12 and later.
- **Mattermost System Console > Integrations > Custom Integrations** in Mattermost
  versions 5.11 and earlier.

Display name override is not enabled by default, you need to ask your administrator to enable it on that same section.

## Configure GitLab to send notifications to Mattermost

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106760) in GitLab 15.9 to limit Mattermost channels to 10 per event.

After the Mattermost instance has an incoming webhook set up, you can set up GitLab
to send the notifications:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Mattermost notifications**.
1. Select the GitLab events to generate notifications for. For each event you select, input the Mattermost channel
   to receive the notification. You do not need to add the hash sign (`#`).
1. Fill in the integration configuration:

   - **Webhook**: The incoming webhook URL on Mattermost, similar to
     `http://mattermost.example/hooks/5xo…`.
   - **Username**: Optional. The username shown in messages sent to Mattermost.
     To change the bot's username, provide a value.
   - **Notify only broken pipelines**: If you enable the **Pipeline** event, and you want
     notifications about failed pipelines only.
   - **Branches for which notifications are to be sent**: The branches to send notifications for.
   - **Labels to be notified**: Optional. Labels required for the issue or merge request
     to trigger a notification. Leave blank to notify for all issues and merge requests.
   - **Labels to be notified behavior**: When you use the **Labels to be notified** filter,
     messages are sent when an issue or merge request contains _any_ of the labels specified
     in the filter. You can also choose to trigger messages only when the issue or merge request
     contains _all_ the labels defined in the filter.
