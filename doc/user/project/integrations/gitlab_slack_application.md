---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab for Slack app
description: "Configure the GitLab for Slack app to use slash commands, receive notifications, and interact with GitLab Duo from your Slack workspace."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> For administrator documentation, see [GitLab for Slack app administration](../../../administration/settings/slack_app.md).

The GitLab for Slack app is a native Slack app that provides [slash commands](#slash-commands), [notifications](#slack-notifications),
and the [GitLab Duo integration](#gitlab-duo) in your Slack workspace. GitLab links your Slack user
with your GitLab user so that any command you run in Slack is run by your linked GitLab user.

## Install the GitLab for Slack app

Prerequisites:

- You must have the [appropriate permissions to add apps to your Slack workspace](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).
- On GitLab Self-Managed, an administrator must [enable the integration](../../../administration/settings/slack_app.md).

The GitLab for Slack app uses
[granular permissions](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3).
Although functionality has not changed, you should [reinstall the app](#reinstall-the-gitlab-for-slack-app).

### From the project or group settings

{{< history >}}

- Installation at the group level [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391526) in GitLab 16.10 [with a feature flag](../../../administration/feature_flags/_index.md) named `gitlab_for_slack_app_instance_and_group_level`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820) in GitLab 16.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803) in GitLab 17.8. Feature flag `gitlab_for_slack_app_instance_and_group_level` removed.

{{< /history >}}

To install the GitLab for Slack app from the project or group settings:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Install GitLab for Slack app**. You're redirected to the Slack confirmation page.
1. On the Slack confirmation page:
   1. Optional. If you're signed in to more than one Slack workspace, in the upper right,
      from the dropdown list, select the workspace you want to install the app in.
      On GitLab Self-Managed and GitLab Dedicated, an administrator must first
      [enable support for multiple workspaces](../../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces) for the dropdown list to appear.
   1. Select **Allow**.

When you install the app at the group level, the integration is also enabled for all subgroups and
projects in the group that don't already have the integration configured. Subgroups and projects
that already have the integration configured are not affected, but can choose to use the inherited
settings at any time. For more information, see [group-level integration management](_index.md#manage-group-default-settings-for-a-project-integration).
Each project gets a project-specific alias based on its project path, which you can use in
[slash commands](#slash-commands).

### From the Slack App Directory

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

On GitLab.com, you can also install the GitLab for Slack app from the
[Slack App Directory](https://slack-platform.slack.com/apps/A676ADMV5-gitlab).

To install the GitLab for Slack app from the Slack App Directory:

1. Go to the [GitLab for Slack page](https://gitlab.com/-/profile/slack/edit).
1. Select a GitLab project to link with your Slack workspace.

## Reinstall the GitLab for Slack app

When GitLab releases new features for the GitLab for Slack app, you might have to reinstall the app to use these features.

To reinstall the GitLab for Slack app:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Install GitLab for Slack app**. You're redirected to the Slack confirmation page.
1. On the Slack confirmation page:
   1. Optional. If you're signed in to more than one Slack workspace, in the upper right,
      from the dropdown list, select the workspace you want to reinstall the app in.
      On GitLab Self-Managed and GitLab Dedicated, an administrator must first
      [enable support for multiple workspaces](../../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces) for the dropdown list to appear.
   1. Select **Allow**.

The GitLab for Slack app is updated for all projects that use the integration.

Alternatively, you can [configure the integration](https://about.gitlab.com/solutions/slack/) again.

## GitLab Duo

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/590434) in GitLab 19.1 [with a feature flag](../../../administration/feature_flags/_index.md) named `slack_duo_agent`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

You can interact with [GitLab Duo](../../gitlab_duo/_index.md) directly from Slack by mentioning the
GitLab bot in any channel or thread where the bot is present. GitLab Duo reads the full
conversation thread as context, runs a flow on a CI/CD runner, and posts the
result back to the Slack thread.

For example, you can ask GitLab Duo to do the following:

- Turn a conversation into a GitLab issue.
- Search for existing issues or merge requests.
- Summarize a discussion thread.
- Answer questions about your projects.

> [!note]
> When you mention the GitLab bot in a thread, the full conversation content
> (including messages from all participants) is sent to a large language model (LLM)
> to generate a response. Do not share sensitive information in threads where you
> mention GitLab Duo.

### Prerequisites

- [Turn on the GitLab Duo Agent Platform](../../duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
- Link a Slack account to your GitLab account.
  If your accounts are not linked, GitLab sends you a message
  with a link to authorize the connection on first mention.
- [Set a default GitLab Duo namespace](../../profile/preferences.md#set-a-default-gitlab-duo-namespace).
- Turn on the [Developer Flow](../../duo_agent_platform/flows/foundational_flows/developer.md) for the top-level group.
- Add the GitLab bot to the Slack channel where you want to use it.
- For existing installations, [reinstall the GitLab for Slack app](#reinstall-the-gitlab-for-slack-app)
  to grant the additional permissions required for GitLab Duo.

### Use GitLab Duo in Slack

To use GitLab Duo in Slack:

1. In a Slack channel or thread, type `@GitLab` followed by your request
   (for example, `@GitLab create an issue to track this bug`).
1. GitLab Duo acknowledges your request and starts working on the task.
1. When the task is complete, GitLab Duo posts a threaded reply with the result.

If an error occurs, GitLab Duo sends you a message with details about the issue.
This message is visible only to you.

### Workspace project

When you first use GitLab Duo from Slack, a workspace project called `duo-workspace`
is automatically created in your default GitLab Duo namespace. This project serves as the
execution environment for any flows triggered from Slack.

You can customize the agent behavior in the workspace project.
For more information, see [Developer Flow](../../duo_agent_platform/flows/foundational_flows/developer.md).

### GitLab for Slack app permissions

GitLab Duo requires the following additional GitLab for Slack app permissions:

| Scope               | Purpose |
|---------------------|---------|
| `app_mentions:read` | Receives events when users mention the bot in a channel. |
| `channels:history`  | Reads conversation history in public channels to provide thread context to the agent. |
| `groups:history`    | Reads conversation history in private channels to provide thread context to the agent. |
| `reactions:write`   | Adds emoji reactions to messages to indicate agent lifecycle status. |

New installations receive these permissions automatically.
Existing installations receive these permissions only after you
[reinstall the GitLab for Slack app](#reinstall-the-gitlab-for-slack-app).

## Slash commands

You can use slash commands to run common GitLab operations.

For the GitLab for Slack app:

- You must authorize your Slack user when you run your first slash command.
- You can replace `<project>` with a project full path or
  [create a project alias](#create-a-project-alias) for slash commands.

If you use [Mattermost slash commands](mattermost_slash_commands.md) instead:

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

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select **GitLab for Slack app**.
1. Next to the project path or alias, select **Edit**.
1. Enter the new alias and select **Save changes**.

If an alias collision occurs in a Slack workspace (for example, multiple projects or groups attempt to use the same alias), GitLab automatically assigns a fallback alias
in the following format:

- For projects: `p-<project_id>` (for example, `p-12345`)
- For groups: `g-<group_id>` (for example, `g-67890`)

You can use these fallback aliases in slash commands when the preferred alias is unavailable.

## Slack notifications

You can receive notifications to Slack channels for certain GitLab [events](#notification-events).

### Configure notifications

To configure Slack notifications:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select **GitLab for Slack app**.
1. In the **Trigger** section:
   - Select the checkbox for each GitLab [event](#notification-events) you want to receive notifications for in Slack.
   - For each checkbox you select, enter the names of the Slack channels you want to receive notifications.
     You can enter up to 10 channel names separated by commas (for example, `#channel-one, #channel-two`).

     > [!note]
     > If the Slack channel is private, you must [add the GitLab for Slack app to the channel](#receive-notifications-to-a-private-channel).

1. Optional. In the **Notification settings** section:
   - Select the **Notify only broken pipelines** checkbox
     to receive notifications for failed pipelines only.
   - Select the **Notify only when status changes** checkbox
     to receive notifications only when the pipeline status for the ref changes.
   - From the **Branches for which notifications are to be sent** dropdown list,
     select the branches you want to receive notifications for.

     Notifications are also sent for pipelines triggered by tags created from these branches.

     Notifications for vulnerabilities are only triggered by the default branch,
     regardless of the selected branches.
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

| Event                                                                 | Description |
| --------------------------------------------------------------------- | ----------- |
| Push                                                                  | A push is made to the repository. |
| Issue                                                                 | A work item is created, closed, or reopened. |
| Confidential issue                                                    | A confidential work item is created, closed, or reopened. |
| Merge request                                                         | A merge request is created, merged, approved, closed, or reopened. |
| Note                                                                  | A comment is added. |
| Confidential note                                                     | An internal note or comment on a confidential work item is added. |
| Tag push                                                              | A tag is pushed to the repository or removed. |
| Pipeline                                                              | A pipeline status changes. |
| Wiki page                                                             | A wiki page is created or updated. |
| Deployment                                                            | A deployment is started or finished. |
| [Group mention](#trigger-notifications-for-group-mentions) in public  | A group is mentioned in a public channel. |
| [Group mention](#trigger-notifications-for-group-mentions) in private | A group is mentioned in a private channel. |
| [Incident](../../../operations/incident_management/slack.md)          | An incident is created, closed, or reopened. |
| [Vulnerability](../../application_security/vulnerabilities/_index.md) | A new, unique vulnerability is recorded on the default branch. |
| Alert                                                                 | A new, unique alert is recorded. |

### Trigger notifications for group mentions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391526) in GitLab 16.10 [with a feature flag](../../../administration/feature_flags/_index.md) named `gitlab_for_slack_app_instance_and_group_level`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820) in GitLab 16.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803) in GitLab 17.8. Feature flag `gitlab_for_slack_app_instance_and_group_level` removed.

{{< /history >}}

To trigger a [notification event](#notification-events) for a group mention, use `@<group_name>` in:

- Issue and merge request descriptions
- Comments on issues, merge requests, and commits
