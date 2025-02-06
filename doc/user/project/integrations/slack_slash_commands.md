---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Slack slash commands
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

NOTE:
This feature is only configurable on GitLab Self-Managed.
For GitLab.com, use the [GitLab for Slack app](gitlab_slack_application.md) instead.

You can use [slash commands](gitlab_slack_application.md#slash-commands) to run common GitLab operations,
like creating an issue, from a [Slack](https://slack.com/) chat environment.
To run slash commands in Slack, you must configure both Slack and GitLab.

GitLab can also send events (such as `issue created`) to Slack as part of
[Slack notifications](gitlab_slack_application.md#slack-notifications).

For a list of available slash commands, see [Slash commands](gitlab_slack_application.md#slash-commands).

## Configure the integration

Slack slash commands are scoped to a project. To configure Slack slash commands:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Slack slash commands** and leave this browser tab open.
1. In a new browser tab, sign in to Slack and [add a new slash command](https://my.slack.com/services/new/slash-commands).
1. Enter a trigger name for the slash command. You could use the project name.
1. Select **Add Slash Command Integration**.
1. In the Slack browser tab:
   1. Complete the fields with information from the GitLab browser tab.
   1. Select **Save Integration** and copy the **Token** value.
1. In the GitLab browser tab:
   1. Paste the token and ensure the **Active** checkbox is selected.
   1. Select **Save changes**.

You can now run slash commands in Slack.
