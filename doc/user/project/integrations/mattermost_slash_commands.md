---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mattermost slash commands
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use [slash commands](gitlab_slack_application.md#slash-commands) to run common GitLab operations,
like creating an issue, from a [Mattermost](https://mattermost.com/) chat environment.

GitLab can also send events (such as `issue created`) to Mattermost as part of the
separately configured [Mattermost notifications](mattermost.md).

For a list of available slash commands, see [Slash commands](gitlab_slack_application.md#slash-commands).

## Configuration options

GitLab provides different ways to configure Mattermost slash commands. For any of these options,
you must have Mattermost [3.4 or later](https://mattermost.com/blog/category/platform/releases/).

- **Linux package installations**: Mattermost is bundled with
  [Linux package](https://docs.gitlab.com/omnibus/). To configure Mattermost for Linux package
  installations, read the [Linux package Mattermost documentation](../../../integration/mattermost/_index.md).
- **If Mattermost is installed on the same server as GitLab**, use the
  [automated configuration](#configure-automatically).
- **For all other installations**, use the [manual configuration](#configure-manually).

## Configure automatically

If Mattermost is installed on the same server as GitLab,
you can automatically configure Mattermost slash commands:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Mattermost slash commands**.
1. Under **Enable integration**, ensure the **Active** checkbox is selected.
1. Select **Add to Mattermost**, and select **Save changes**.

## Configure manually

To manually configure slash commands in Mattermost, you must:

1. [Enable custom slash commands in Mattermost](#enable-custom-slash-commands-in-mattermost).
   This step is required only for self-compiled installations.
1. [Get configuration values from GitLab](#get-configuration-values-from-gitlab).
1. [Create a slash command in Mattermost](#create-a-slash-command-in-mattermost).
1. [Provide the Mattermost token to GitLab](#provide-the-mattermost-token-to-gitlab).

### Enable custom slash commands in Mattermost

To enable custom slash commands from the Mattermost administrator console:

1. Sign in to Mattermost as a user with administrator privileges.
1. Next to your username, select the **{ellipsis_v}** **Settings** icon, and
   select **System Console**.
1. Select **Integration Management**, and set these values to `TRUE`:
   - **Enable Custom Slash Commands**
   - **Enable integrations to override usernames**
   - **Enable integrations to override profile picture icons**
1. Select **Save**, but do not close this browser tab. You need it in
   a later step.

### Get configuration values from GitLab

To get configuration values from GitLab:

1. In a different browser tab, sign in to
   GitLab as a user with administrator access.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.
1. Select **Mattermost slash commands**. GitLab displays potential values for Mattermost settings.
1. Copy the **Request URL** value. All other values are suggestions.
1. Do not close this browser tab. You need it in a later step.

### Create a slash command in Mattermost

To create a slash command in Mattermost:

1. [In the Mattermost browser tab](#enable-custom-slash-commands-in-mattermost),
   go to your team page.
1. Select the **{ellipsis_v}** **Settings** icon, and select **Integrations**.
1. On the left sidebar, select **Slash commands**.
1. Select **Add Slash Command**.
1. Provide a **Display Name** and **Description** for your new command.
1. Provide a **Command Trigger Word** based on your application's configuration:

   - **If you intend to only connect one project to your Mattermost team**, use
     `/gitlab` for your trigger word.
   - **If you intend to connect multiple projects**, use a trigger word that relates
     to your project, such as `/project-name` or `/gitlab-project-name`.
1. For **Request URL**, [paste the value you copied from GitLab](#get-configuration-values-from-gitlab).
1. For all other values, you may use the suggestions from GitLab or your
   preferred values.
1. Copy the **Token** value, and select **Done**.

### Provide the Mattermost token to GitLab

Creating a slash command in Mattermost generates a token you must
provide to GitLab:

1. [In the GitLab browser tab](#get-configuration-values-from-gitlab),
   select the **Active** checkbox.
1. In the **Token** text box, [paste the token you copied from Mattermost](#create-a-slash-command-in-mattermost).
1. Select **Save changes**.

Your slash command can now communicate with your GitLab project.

## Connect your GitLab account to Mattermost

Prerequisites:

- To run [slash commands](gitlab_slack_application.md#slash-commands), you must have
  [permission](../../permissions.md#project-members-permissions) to
  perform the action in the GitLab project.

To interact with GitLab using Mattermost slash commands:

1. In a Mattermost chat environment, run your new slash command.
1. Select **connect your GitLab account** to authorize access.

You can see all authorized chat accounts in your Mattermost profile page under **Chat**.

## Related topics

- [Mattermost Linux package](../../../integration/mattermost/_index.md)
- [Slash commands at Mattermost](https://developers.mattermost.com/integrate/slash-commands/)

## Troubleshooting

When a Mattermost slash command does not trigger an event in GitLab:

- Ensure you're using a public channel.
  Mattermost webhooks do not have access to private channels.
- If you require a private channel, edit the webhook channel,
  and select a private one. All events are sent to the specified channel.
