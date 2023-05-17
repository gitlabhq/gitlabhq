---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab for Slack app **(FREE SAAS)**

NOTE:
This feature is only configurable on GitLab.com.
For self-managed GitLab instances, use
[Slack slash commands](slack_slash_commands.md) and [Slack notifications](slack.md) instead.
For more information about our plans to make this feature configurable for all GitLab installations,
see [epic 1211](https://gitlab.com/groups/gitlab-org/-/epics/1211).

Slack provides a native application that you can enable with your project's
integrations on GitLab.com.

## Installation

In GitLab 15.0 and later, the GitLab for Slack app uses
[granular permissions](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3).
Although functionality has not changed, you should [reinstall the app](#update-the-gitlab-for-slack-app).

### Through the Slack App Directory

To enable the GitLab for Slack app for your workspace,
install the [GitLab application](https://slack-platform.slack.com/apps/A676ADMV5-gitlab)
from the [Slack App Directory](https://slack.com/apps).

On the [GitLab for Slack app landing page](https://gitlab.com/-/profile/slack/edit),
you can select a GitLab project to link with your Slack workspace.

### Through GitLab project settings

Alternatively, you can configure the GitLab for Slack app with your project's
integration settings.

You must have the appropriate permissions for your Slack
workspace to be able to install a new application. See
[Add apps to your Slack workspace](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).

To enable the GitLab integration for your Slack workspace:

1. Go to your project's **Settings > Integration > GitLab for Slack app** (only
   visible on GitLab.com).
1. Select **Install GitLab for Slack app**.
1. Select **Allow** on Slack's confirmation screen.

To update the app in your Slack workspace to the latest version,
you can also select **Reinstall GitLab for Slack app**.

## Slash commands

After installing the GitLab for Slack app, everyone in your Slack workspace can use slash commands.

Replace `<project>` with the project full path, or create a shorter [project alias](#create-a-project-alias-for-slash-commands) for the slash commands.

| Command | Effect |
| ------- | ------ |
| `/gitlab help` | Shows all available slash commands. |
| `/gitlab <project> issue new <title> <shift+return> <description>` | Creates a new issue with the title `<title>` and description `<description>`. |
| `/gitlab <project> issue show <id>` | Shows the issue with the ID `<id>`. |
| `/gitlab <project> issue close <id>` | Closes the issue with the ID `<id>`. |
| `/gitlab <project> issue search <query>` | Shows up to 5 issues matching `<query>`. |
| `/gitlab <project> issue move <id> to <project>` | Moves the issue with the ID `<id>` to `<project>`. |
| `/gitlab <project> issue comment <id> <shift+return> <comment>` | Adds a new comment with the comment body `<comment>` to the issue with the ID `<id>`. |
| `/gitlab <project> deploy <from> to <to>` | [Deploys](#the-deploy-slash-command) from the `<from>` environment to the `<to>` environment. |
| `/gitlab <project> run <job name> <arguments>` | Executes the [ChatOps](../../../ci/chatops/index.md) job `<job name>` on the default branch. |
| `/gitlab incident declare` | **Beta** Opens modal to [create a new incident](../../../operations/incident_management/slack.md). |

### The deploy slash command

To deploy to an environment, GitLab tries to find a deployment
manual action in the pipeline.

If there's only one action for a given environment, it is triggered.
If more than one action is defined, GitLab finds an action
name that matches the environment name to deploy to.

The command returns an error if no matching action is found.

### User authorization

When you perform your first slash command, you must
authorize your Slack user on GitLab.com.

### Create a project alias for slash commands

By default, slash commands expect a project full path. To use a shorter alias
instead:

1. Go to your project's home page.
1. Go to **Settings > Integrations** (only visible on GitLab.com).
1. On the **Integrations** page, select **GitLab for Slack app**.
1. The current **Project Alias**, if any, is displayed. To edit this value,
   select **Edit**.
1. Enter your desired alias, and select **Save changes**.

## Slack notifications

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381012) in GitLab 15.9.

With Slack notifications, GitLab can send messages to Slack workspace channels for certain GitLab [events](#events-for-slack-notifications) (for example, when an issue is created).

### Configure notifications

To configure Slack notifications:

1. On the top bar, select **Main menu > Projects** and find a project for which the GitLab for Slack app has been [installed](#installation).
1. On the left sidebar, select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. In the **Trigger** section, select the checkbox for each GitLab
   event you want to receive a notification for in Slack. For a full list, see
   [Events for Slack notifications](#events-for-slack-notifications).
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

### Events for Slack notifications

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

### Update the GitLab for Slack app

New releases of the app might require permissions to be authorized before some features work in your Slack workspace. You should ensure the app is up to date in your Slack workspace to enjoy all the latest features.

To update your GitLab for Slack app:

1. On the top bar, select **Main menu > Projects** and find a project for which the GitLab for Slack app has been configured.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Reinstall GitLab for Slack app**.

The GitLab for Slack app is updated for all projects that use the integration.

Alternatively, you can [configure a new Slack integration](https://about.gitlab.com/solutions/slack/).

### Project or alias not found

Some Slack commands must have a project full path or alias and fail with the following error
if the project cannot be found:

```plaintext
GitLab error: project or alias not found
```

As a workaround, ensure:

- The project full path is correct.
- If using a [project alias](#create-a-project-alias-for-slash-commands), the alias is correct.
- The GitLab for Slack app integration is [enabled for the project](#through-gitlab-project-settings).

### Notifications are not received to a channel

If you're not receiving notifications to a Slack channel, ensure:

- The channel name you configured is correct.
- If the channel is private, you've [added the GitLab for Slack app to the channel](#receive-notifications-to-a-private-channel).

### The App Home does not display properly

If the [App Home](https://api.slack.com/start/overview#app_home) does not display properly, ensure your [app is up to date](#update-the-gitlab-for-slack-app).
