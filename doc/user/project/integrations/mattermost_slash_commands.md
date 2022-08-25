---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Mattermost slash commands **(FREE)**

You can use slash commands to run common GitLab operations, like creating an issue,
from a [Mattermost](https://mattermost.com/) chat environment.

GitLab can also send events (such as `issue created`) to Mattermost as part of the
separately configured [Mattermost notifications](mattermost.md).

## Configuration options

GitLab provides different ways to configure Mattermost slash commands. For any of these options,
you must have Mattermost [3.4 or later](https://mattermost.com/blog/category/platform/releases/).

- **Omnibus GitLab installations**: Mattermost is bundled with
  [Omnibus GitLab](https://docs.gitlab.com/omnibus/). To configure Mattermost for Omnibus GitLab,
  read the [Omnibus GitLab Mattermost documentation](../../../integration/mattermost/index.md).
- **If Mattermost is installed on the same server as GitLab**, use the
  [automated configuration](#configure-automatically).
- **For all other installations**, use the [manual configuration](#configure-manually).

## Configure automatically

If Mattermost is installed on the same server as GitLab,
you can automatically configure Mattermost slash commands:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. In **Add an integration**, select **Mattermost slash commands**.
1. In **Enable integration**, ensure the **Active** checkbox is selected.
1. Select **Add to Mattermost**, and select **Save changes**.

## Configure manually

To manually configure slash commands in Mattermost, you must:

1. [Enable custom slash commands in Mattermost](#enable-custom-slash-commands-in-mattermost).
   (This step is required only for installations from source.)
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
1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Integrations**.
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

## Authorizing Mattermost to interact with GitLab

The first time a user interacts with the newly created slash commands,
Mattermost triggers an authorization process.

![Mattermost bot authorize](img/mattermost_bot_auth.png)

This connects your Mattermost user with your GitLab user. You can
see all authorized chat accounts in your profile's page under **Chat**.

When the authorization process is complete, you can start interacting with
GitLab using the Mattermost commands.

## Available slash commands

The available slash commands for Mattermost are:

| Command | Description | Example |
| ------- | ----------- | ------- |
| <kbd>/&lt;trigger&gt; issue new &lt;title&gt; <kbd>⇧ Shift</kbd>+<kbd>↵ Enter</kbd> &lt;description&gt;</kbd> | Create a new issue in the project that `<trigger>` is tied to. `<description>` is optional. | `/gitlab issue new We need to change the homepage` |
| <kbd>/&lt;trigger&gt; issue show &lt;issue-number&gt;</kbd> | Show the issue with ID `<issue-number>` from the project that `<trigger>` is tied to. | `/gitlab issue show 42` |
| <kbd>/&lt;trigger&gt; deploy &lt;environment&gt; to &lt;environment&gt;</kbd> | Start the CI job that deploys from one environment to another, for example `staging` to `production`. CI/CD must be [properly configured](../../../ci/yaml/index.md). | `/gitlab deploy staging to production` |

To see a list of available commands to interact with GitLab, type the
trigger word followed by <kbd>help</kbd>. Example: `/gitlab help`

![Mattermost bot available commands](img/mattermost_bot_available_commands.png)

## Permissions

The permissions to run the [available commands](#available-slash-commands) derive from
the [permissions you have on the project](../../permissions.md#project-members-permissions).

## Troubleshooting

If an event is not being triggered, confirm that the channel you're using is a public one.
Mattermost webhooks do not have access to private channels.

If a private channel is required, you can edit the webhook's channel in Mattermost and
select a private channel. It is not possible to use different channels for
different types of notifications. All events are sent to the specified channel.

## Further reading

- [Mattermost slash commands documentation](https://docs.mattermost.com/developer/slash-commands.html)
- [Omnibus GitLab Mattermost](../../../integration/mattermost/)
