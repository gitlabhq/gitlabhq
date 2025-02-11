---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab for Slack app
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358872) for GitLab Self-Managed in GitLab 16.2.

NOTE:
This page contains user documentation for the GitLab for Slack app. For administrator documentation, see [GitLab for Slack app administration](../../../administration/settings/slack_app.md).

The GitLab for Slack app is a native Slack app that provides [slash commands](#slash-commands) and [notifications](#slack-notifications)
in your Slack workspace. GitLab links your Slack user with your GitLab user so that any command
you run in Slack is run by your linked GitLab user.

## Install the GitLab for Slack app

Prerequisites:

- You must have the [appropriate permissions to add apps to your Slack workspace](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).
- On GitLab Self-Managed, an administrator must [enable the integration](../../../administration/settings/slack_app.md).

In GitLab 15.0 and later, the GitLab for Slack app uses
[granular permissions](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3).
Although functionality has not changed, you should [reinstall the app](#reinstall-the-gitlab-for-slack-app).

### From the project or group settings

> - Installation at the group level [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391526) in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `gitlab_for_slack_app_instance_and_group_level`. Disabled by default.
> - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820) in GitLab 16.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803) in GitLab 17.8. Feature flag `gitlab_for_slack_app_instance_and_group_level` removed.

To install the GitLab for Slack app from the project or group settings:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Install GitLab for Slack app**.
1. On the Slack confirmation page, select **Allow**.

### From the Slack App Directory

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

On GitLab.com, you can also install the GitLab for Slack app from the
[Slack App Directory](https://slack-platform.slack.com/apps/A676ADMV5-gitlab).

To install the GitLab for Slack app from the Slack App Directory:

1. Go to the [GitLab for Slack page](https://gitlab.com/-/profile/slack/edit).
1. Select a GitLab project to link with your Slack workspace.

## Reinstall the GitLab for Slack app

When GitLab releases new features for the GitLab for Slack app, you might have to reinstall the app to use these features.

To reinstall the GitLab for Slack app:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Reinstall GitLab for Slack app**.
1. On the Slack confirmation page, select **Allow**.

The GitLab for Slack app is updated for all projects that use the integration.

Alternatively, you can [configure the integration](https://about.gitlab.com/solutions/slack/) again.

## Slash commands

You can use slash commands to run common GitLab operations.

For the GitLab for Slack app:

- You must authorize your Slack user when you run your first slash command.
- You can replace `<project>` with a project full path or
  [create a project alias](#create-a-project-alias) for slash commands.

If you use [Slack slash commands](slack_slash_commands.md) or
[Mattermost slash commands](mattermost_slash_commands.md) instead:

- Replace `/gitlab` with the trigger name you've configured for these integrations.
- Remove `<project>`.

The following slash commands are available for GitLab:

| Command | Description |
| ------- | ----------- |
| `/gitlab help` | Shows all available slash commands. |
| `/gitlab <project> issue show <id>` | Shows the issue with the ID `<id>`. |
| `/gitlab <project> issue new <title>` <kbd>Shift</kbd>+<kbd>Enter</kbd> `<description>` | Creates an issue with the title `<title>` and description `<description>`. |
| `/gitlab <project> issue search <query>` | Shows up to five issues that match `<query>`. |
| `/gitlab <project> issue move <id> to <project>` | Moves the issue with the ID `<id>` to `<project>`. |
| `/gitlab <project> issue close <id>` | Closes the issue with the ID `<id>`. |
| `/gitlab <project> issue comment <id>` <kbd>Shift</kbd>+<kbd>Enter</kbd> `<comment>` | Adds a comment with the comment body `<comment>` to the issue with the ID `<id>`. |
| `/gitlab <project> deploy <from> to <to>` | [Deploys](#deploy-command) from the `<from>` environment to the `<to>` environment. |
| `/gitlab <project> run <job name> <arguments>` | Executes the [ChatOps](../../../ci/chatops/_index.md) job `<job name>` on the default branch. |
| `/gitlab incident declare` | Opens a dialog to [create an incident from Slack](../../../operations/incident_management/slack.md). |

### `deploy` command

To deploy to an environment, GitLab tries to find a manual deployment action in the pipeline.

If only one deployment action is defined for an environment, that action is triggered.
If more than one deployment action is defined, GitLab tries to find an action name
that matches the environment name.

The command returns an error if GitLab cannot find a matching deployment action.

### Create a project alias

In the GitLab for Slack app, slash commands use a project full path by default.
You can use a project alias instead.

To create a project alias for slash commands in the GitLab for Slack app:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. Next to the project path or alias, select **Edit**.
1. Enter the new alias and select **Save changes**.

## Slack notifications

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381012) in GitLab 15.9.

You can receive notifications to Slack channels for certain GitLab [events](#notification-events).

### Configure notifications

To configure Slack notifications:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. In the **Trigger** section:
   - Select the checkbox for each GitLab [event](#notification-events) you want to receive notifications for in Slack.
   - For each checkbox you select, enter the names of the Slack channels you want to receive notifications.
     You can enter up to 10 channel names separated by commas (for example, `#channel-one, #channel-two`).

     NOTE:
     If the Slack channel is private, you must [add the GitLab for Slack app to the channel](#receive-notifications-to-a-private-channel).

1. Optional. In the **Notification settings** section:
   - Select the **Notify only broken pipelines** checkbox
     to receive notifications for failed pipelines only.
   - From the **Branches for which notifications are to be sent** dropdown list,
     select the branches you want to receive notifications for. Notifications
     for vulnerabilities are only triggered by the default branch, regardless
     of the selected branches.
     For more details, see [issue 469373](https://gitlab.com/gitlab-org/gitlab/-/issues/469373).
   - For **Labels to be notified**, enter any or all of the labels a GitLab
     issue, merge request, or comment must have to receive notifications for.
     Leave blank to receive notifications for all events.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

### Receive notifications to a private channel

To receive notifications to a private Slack channel, you must add the GitLab for Slack app to the channel:

1. Mention the app in the channel by entering `@GitLab`.
1. Select **Add to Channel**.

### Notification events

The following GitLab events can trigger notifications in Slack:

| Event                                                                 | Description                                                   |
|-----------------------------------------------------------------------|---------------------------------------------------------------|
| Push                                                                  | A push is made to the repository.                             |
| Issue                                                                 | An issue is created, closed, or reopened.                     |
| Confidential issue                                                    | A confidential issue is created, closed, or reopened.         |
| Merge request                                                         | A merge request is created, merged, closed, or reopened.      |
| Note                                                                  | A comment is added.                                           |
| Confidential note                                                     | An internal note or comment on a confidential issue is added. |
| Tag push                                                              | A tag is pushed to the repository or removed.                 |
| Pipeline                                                              | A pipeline status changes.                                    |
| Wiki page                                                             | A wiki page is created or updated.                            |
| Deployment                                                            | A deployment is started or finished.                          |
| [Group mention](#trigger-notifications-for-group-mentions) in public  | A group is mentioned in a public channel.                     |
| [Group mention](#trigger-notifications-for-group-mentions) in private | A group is mentioned in a private channel.                    |
| [Incident](../../../operations/incident_management/slack.md)          | An incident is created, closed, or reopened.                  |
| [Vulnerability](../../application_security/vulnerabilities/_index.md)  | A new, unique vulnerability is recorded on the default branch.|
| Alert                                                                 | A new, unique alert is recorded.                              |

### Trigger notifications for group mentions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391526) in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `gitlab_for_slack_app_instance_and_group_level`. Disabled by default.
> - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820) in GitLab 16.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803) in GitLab 17.8. Feature flag `gitlab_for_slack_app_instance_and_group_level` removed.

To trigger a [notification event](#notification-events) for a group mention, use `@<group_name>` in:

- Issue and merge request descriptions
- Comments on issues, merge requests, and commits
