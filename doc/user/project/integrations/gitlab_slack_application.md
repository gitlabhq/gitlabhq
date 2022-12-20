---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab for Slack app **(FREE SAAS)**

NOTE:
The GitLab for Slack app is only configurable for GitLab.com. It does **not**
work for on-premises installations where you can configure
[Slack slash commands](slack_slash_commands.md) instead. See
[Slack application integration for self-managed instances](https://gitlab.com/groups/gitlab-org/-/epics/1211)
for our plans to make the app configurable for all GitLab installations.

Slack provides a native application that you can enable with your project's
integrations on GitLab.com.

## Slack App Directory

To enable the GitLab for Slack app for your workspace,
install the [GitLab application](https://slack-platform.slack.com/apps/A676ADMV5-gitlab)
from the [Slack App Directory](https://slack.com/apps).

On the [GitLab for Slack app landing page](https://gitlab.com/-/profile/slack/edit),
you can select a GitLab project to link with your Slack workspace.

## Configuration

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

You can also select **Reinstall GitLab for Slack app** to update the app in your Slack workspace
to the latest version. See [Version history](#version-history) for details.

## Create a project alias for Slack

To create a project alias on GitLab.com for Slack integration:

1. Go to your project's home page.
1. Go to **Settings > Integrations** (only visible on GitLab.com).
1. On the **Integrations** page, select **GitLab for Slack app**.
1. The current **Project Alias**, if any, is displayed. To edit this value,
   select **Edit**.
1. Enter your desired alias, and select **Save changes**.

Some Slack commands require a project alias and fail with the following error
if the project alias is incorrect or missing from the command:

```plaintext
GitLab error: project or alias not found
```

## Usage

After installing the app, everyone in your Slack workspace can
use the [slash commands](../../../integration/slash_commands.md).
When you perform your first slash command, you are asked to
authorize your Slack user on GitLab.com.

The only difference with the [manually configurable Slack slash commands](slack_slash_commands.md)
is that you must prefix all commands with the `/gitlab` keyword. For example,
to show the issue number `1001` under the `gitlab-org/gitlab`
project, you must run the following command:

```plaintext
/gitlab gitlab-org/gitlab issue show 1001
```

## Version history

In GitLab 15.0 and later, the GitLab for Slack app is updated to [Slack's new granular permissions model](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3). While there is no change in functionality, you should reinstall the app.

## Troubleshooting

When you work with the GitLab for Slack app, the
[App Home](https://api.slack.com/start/overview#app_home) might not display properly.
As a workaround, ensure your app is up to date.

To update an existing Slack integration:

1. Go to your [chat settings](https://gitlab.com/-/profile/chat_names).
1. Next to your project, select **GitLab for Slack app**.
1. Select **Reinstall GitLab for Slack app**.

Alternatively, you can [configure a new Slack integration](https://about.gitlab.com/solutions/slack/).
