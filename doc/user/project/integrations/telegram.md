---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Telegram **(FREE ALL)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122879) in GitLab 16.1.

You can configure GitLab to send notifications to a Telegram chat or channel.
To set up the Telegram integration, you must:

1. [Create a Telegram bot](#create-a-telegram-bot).
1. [Configure the Telegram bot](#configure-the-telegram-bot).
1. [Set up the Telegram integration in GitLab](#set-up-the-telegram-integration-in-gitlab).

## Create a Telegram bot

To create a bot in Telegram:

1. Start a new chat with `@BotFather`.
1. [Create a new bot](https://core.telegram.org/bots/features#creating-a-new-bot) as described in the Telegram documentation.

When you create a bot, `BotFather` provides you with an API token. Keep this token secure as you need it to authenticate the bot in Telegram.

## Configure the Telegram bot

To configure the bot in Telegram:

1. Add the bot as an administrator to a new or existing channel.
1. Assign the bot `Post Messages` rights to receive events.
1. Create an identifier for the channel.
   - For public channels, enter a public link and copy the channel identifier (for example, `https:/t.me/MY_IDENTIFIER`).
   - For private channels, use the [`getUpdates`](https://telegram-bot-sdk.readme.io/reference/getupdates) method with your API token and copy the channel identifier (for example, `-2241293890657`).

## Set up the Telegram integration in GitLab

After you invite the bot to a Telegram channel, you can configure GitLab to send notifications:

1. To enable the integration:
   - **For your group or project:**
     1. On the left sidebar, select **Search or go to** and find your project or group.
     1. Select **Settings > Integrations**.
   - **For your instance:**
     1. On the left sidebar, at the bottom, select **Admin Area**.
     1. Select **Settings > Integrations**.
1. Select **Telegram**.
1. Under **Enable integration**, select the **Active** checkbox.
1. In **New token**, [paste the token value from the Telegram bot](#create-a-telegram-bot).
1. In the **Trigger** section, select the checkboxes for the GitLab events you want to receive in Telegram.
1. In **Channel identifier**, [paste the Telegram channel identifier](#configure-the-telegram-bot).
1. Optional. Select **Test settings**.
1. Select **Save changes**.

The Telegram channel can now receive all selected GitLab events.
