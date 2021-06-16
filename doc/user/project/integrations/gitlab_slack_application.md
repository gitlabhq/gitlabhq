---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Slack application **(FREE SAAS)**

> - Introduced in GitLab 9.4.
> - Distributed to Slack App Directory in GitLab 10.2.

NOTE:
The GitLab Slack application is only configurable for GitLab.com. It will **not**
work for on-premises installations where you can configure the
[Slack slash commands](slack_slash_commands.md) service instead. We're planning
to make this configurable for all GitLab installations, but there's
no ETA - see [#28164](https://gitlab.com/gitlab-org/gitlab/-/issues/28164).

Slack provides a native application which you can enable via your project's
integrations on GitLab.com.

## Slack App Directory

The simplest way to enable the GitLab Slack application for your workspace is to
install the [GitLab application](https://slack-platform.slack.com/apps/A676ADMV5-gitlab) from
the [Slack App Directory](https://slack.com/apps).

Clicking install takes you to the [GitLab Slack application landing page](https://gitlab.com/-/profile/slack/edit)
where you can select a project to enable the GitLab Slack application for.

![GitLab Slack application landing page](img/gitlab_slack_app_landing_page.png)

## Configuration

Alternatively, you can configure the Slack application with a project's
integration settings.

Keep in mind that you need to have the appropriate permissions for your Slack
team in order to be able to install a new application, read more in Slack's
docs on [Adding an app to your workspace](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).

To enable the GitLab service for your Slack team:

1. Go to your project's **Settings > Integration > Slack application** (only
   visible on GitLab.com).
1. Click **Add to Slack**.

That's all! You can now start using the Slack slash commands.

## Create a project alias for Slack

To create a project alias on GitLab.com for Slack integration:

1. Go to your project's home page.
1. Navigate to **Settings > Integrations** (only visible on GitLab.com)
1. On the **Integrations** page, click **Slack application**.
1. The current **Project Alias**, if any, is displayed. To edit this value,
   click **Edit**.
1. Enter your desired alias, and click **Save changes**.

Some Slack commands require a project alias, and fail with the following error
if the project alias is incorrect or missing from the command:

```plaintext
GitLab error: project or alias not found
```

## Usage

After confirming the installation, you, and everyone else in your Slack team,
can use all the [slash commands](../../../integration/slash_commands.md).

When you perform your first slash command, you are asked to authorize your
Slack user on GitLab.com.

The only difference with the [manually configurable Slack slash commands](slack_slash_commands.md)
is that all the commands should be prefixed with the `/gitlab` keyword.
We are working on making this configurable in the future.

For example, to show the issue number `1001` under the `gitlab-org/gitlab`
project, you would do:

```plaintext
/gitlab gitlab-org/gitlab issue show 1001
```
