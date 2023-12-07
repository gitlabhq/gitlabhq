---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab for Slack app **(FREE ALL)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358872) for self-managed instances in GitLab 16.2.

NOTE:
This page contains information about configuring the GitLab for Slack app on GitLab.com. For administrator documentation, see [GitLab for Slack app administration](../../../administration/settings/slack_app.md).

The GitLab for Slack app is a native Slack app that provides [slash commands](#slash-commands) and [notifications](#slack-notifications)
in your Slack workspace. GitLab links your Slack user with your GitLab user so that any command
you run in Slack is run by your linked GitLab user.

## Install the GitLab for Slack app

Prerequisites:

- You must have the [appropriate permissions to add apps to your Slack workspace](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).
- On self-managed GitLab, an administrator must [enable the integration](../../../administration/settings/slack_app.md).

In GitLab 15.0 and later, the GitLab for Slack app uses
[granular permissions](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3).
Although functionality has not changed, you should [reinstall the app](#update-the-gitlab-for-slack-app).

### From project integration settings

To install the GitLab for Slack app from project integration settings:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Install GitLab for Slack app**.
1. On the Slack confirmation page, select **Allow**.

To update the app in your Slack workspace to the latest version,
you can also select **Reinstall GitLab for Slack app**.

### From the Slack App Directory **(FREE SAAS)**

On GitLab.com, you can also install the GitLab for Slack app from the
[Slack App Directory](https://slack-platform.slack.com/apps/A676ADMV5-gitlab).

To install the GitLab for Slack app from the Slack App Directory:

1. Go to the [GitLab for Slack page](https://gitlab.com/-/profile/slack/edit).
1. Select a GitLab project to link with your Slack workspace.

## Update the GitLab for Slack app

When GitLab releases new features for the GitLab for Slack app, you might have to manually update your app to use the new features.

To update your GitLab for Slack app:

1. On the left sidebar, select **Search or go to** and find a project for
   which the GitLab for Slack app is configured.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Reinstall GitLab for Slack app**.

The GitLab for Slack app is updated for all projects that use the integration.

Alternatively, you can [configure the integration](https://about.gitlab.com/solutions/slack/) again.

## Slash commands

You can use slash commands to run common GitLab operations. Replace `<project>` with a project full path.

**For the GitLab for Slack app**:

- You must authorize your Slack user on GitLab.com when you run your first slash command.
- You can [create a shorter project alias](#create-a-project-alias-for-slash-commands) for slash commands.

**For [Slack slash commands](slack_slash_commands.md) on self-managed GitLab and [Mattermost slash commands](mattermost_slash_commands.md)**,
replace `/gitlab` with the slash command trigger name configured for your integration.

The following slash commands are available:

| Command | Description |
| ------- | ----------- |
| `/gitlab help` | Shows all available slash commands. |
| `/gitlab <project> issue new <title>` <kbd>Shift</kbd>+<kbd>Enter</kbd> `<description>` | Creates a new issue with the title `<title>` and description `<description>`. |
| `/gitlab <project> issue show <id>` | Shows the issue with the ID `<id>`. |
| `/gitlab <project> issue close <id>` | Closes the issue with the ID `<id>`. |
| `/gitlab <project> issue search <query>` | Shows up to five issues matching `<query>`. |
| `/gitlab <project> issue move <id> to <project>` | Moves the issue with the ID `<id>` to `<project>`. |
| `/gitlab <project> issue comment <id>` <kbd>Shift</kbd>+<kbd>Enter</kbd> `<comment>` | Adds a new comment with the comment body `<comment>` to the issue with the ID `<id>`. |
| `/gitlab <project> deploy <from> to <to>` | [Deploys](#the-deploy-slash-command) from the `<from>` environment to the `<to>` environment. |
| `/gitlab <project> run <job name> <arguments>` | Executes the [ChatOps](../../../ci/chatops/index.md) job `<job name>` on the default branch. |
| `/gitlab incident declare` | Opens a dialog to [create a new incident from Slack](../../../operations/incident_management/slack.md) (Beta). |

### The `deploy` slash command

To deploy to an environment, GitLab tries to find a deployment manual action in the pipeline.

If only one action is defined for a given environment, it is triggered.
If more than one action is defined, GitLab tries to find an action name
that matches the environment name to deploy to.

The command returns an error if no matching action is found.

### Create a project alias for slash commands

By default, slash commands expect a project full path. To create a shorter project alias in the GitLab for Slack app:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. The current **Project Alias**, if any, is displayed. To edit this value,
   select **Edit**.
1. Enter your desired alias, and select **Save changes**.

## Slack notifications

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381012) in GitLab 15.9.

With Slack notifications, GitLab can send messages to Slack workspace channels for certain GitLab [events](#notification-events).

### Configure notifications

To configure Slack notifications:

1. On the left sidebar, select **Search or go to** and find a project for
   which the GitLab for Slack app is [installed](#install-the-gitlab-for-slack-app).
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. In the **Trigger** section, select the checkbox for each GitLab
   event you want to receive a notification for in Slack. For a full list, see
   [Notification events](#notification-events).
1. For each checkbox you select, enter the name of the channel that receives the notifications (for example, `#my-channel`).
    - To send notifications to multiple Slack channels, enter up to 10 channel names separated by commas (for example, `#channel-one, #channel-two`).

   NOTE:
   If the channel is private, you must also [add the GitLab for Slack app to the private channel](#receive-notifications-to-a-private-channel).

1. Select the **Notify only broken pipelines** checkbox to notify only on failures.
1. From the **Branches for which notifications are to be sent** dropdown list, select which branches you want to receive notifications (if relevant to your events).
1. Leave the **Labels to be notified** text box blank to receive all notifications, or
   add labels the issue or merge request must have to trigger a
   notification.
1. Select **Save changes**.

Your Slack workspace can now start receiving GitLab event notifications.

### Receive notifications to a private channel

To receive notifications to a private Slack channel, you must add the GitLab for Slack app to the channel:

1. Mention the app in the channel by typing `@GitLab` and pressing <kbd>Enter</kbd>.
1. Select **Add to Channel**.

### Notification events

The following events are available for Slack notifications:

| Event name                                                             | Description                                        |
|--------------------------------------------------------------------------|------------------------------------------------------|
| **Push**                                                                 | A push to the repository.                            |
| **Issue**                                                                | An issue is created, updated, or closed.             |
| **Confidential issue**                                                   | A confidential issue is created, updated, or closed. |
| **Merge request**                                                        | A merge request is created, updated, or merged.      |
| **Note**                                                                 | A comment is added.                                  |
| **Confidential note**                                                    | A confidential note is added.                        |
| **Tag push**                                                             | A new tag is pushed to the repository.               |
| **Pipeline**                                                             | A pipeline status changed.                           |
| **Wiki page**                                                            | A wiki page is created or updated.                   |
| **Deployment**                                                           | A deployment starts or finishes.                     |
| **Alert**                                                                | A new, unique alert is recorded.                     |
| [**Vulnerability**](../../application_security/vulnerabilities/index.md) | A new, unique vulnerability is recorded.             |

## Troubleshooting

When configuring the GitLab for Slack app on GitLab.com, you might encounter the following issues.

For self-managed GitLab, see [GitLab for Slack app administration](../../../administration/settings/slack_app.md#troubleshooting).

### The app does not appear in the list of integrations

The GitLab for Slack app might not appear in the list of integrations. To have the GitLab for Slack app on your self-managed instance, an administrator must [enable the integration](../../../administration/settings/slack_app.md). On GitLab.com, the GitLab for Slack app is available by default.

The GitLab for Slack app is enabled at the project level only. Support for the app at the group and instance levels is proposed in [issue 391526](https://gitlab.com/gitlab-org/gitlab/-/issues/391526).

### Project or alias not found

Some Slack commands must have a project full path or alias and fail with the following error
if the project cannot be found:

```plaintext
GitLab error: project or alias not found
```

As a workaround, ensure:

- The project full path is correct.
- If using a [project alias](#create-a-project-alias-for-slash-commands), the alias is correct.
- The GitLab for Slack app is [enabled for the project](#from-project-integration-settings).

### Slash commands return an error in Slack

Slash commands might return `/gitlab failed with the error "dispatch_failed"` in Slack.
To resolve this issue, ensure an administrator has properly configured the [GitLab for Slack app settings](../../../administration/settings/slack_app.md) on your self-managed instance.

### Notifications are not received to a channel

If you're not receiving notifications to a Slack channel, ensure:

- The channel name you configured is correct.
- If the channel is private, you've [added the GitLab for Slack app to the channel](#receive-notifications-to-a-private-channel).

### The App Home does not display properly

If the [App Home](https://api.slack.com/start/overview#app_home) does not display properly, ensure your [app is up to date](#update-the-gitlab-for-slack-app).
