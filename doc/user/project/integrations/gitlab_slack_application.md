---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Slack application **(FREE SAAS)**

NOTE:
The GitLab Slack application is only configurable for GitLab.com. It will **not**
work for on-premises installations where you can configure the
[Slack slash commands](slack_slash_commands.md) integration instead. We're planning
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

## Configuration

Alternatively, you can configure the Slack application with a project's
integration settings.

Keep in mind that you must have the appropriate permissions for your Slack
workspace to be able to install a new application. Read more in Slack's
documentation on [Adding an app to your workspace](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).

To enable the GitLab integration for your Slack workspace:

1. Go to your project's **Settings > Integration > Slack application** (only
   visible on GitLab.com).
1. Select **Install Slack app**.
1. Select **Allow** on Slack's confirmation screen.

That's all! You can now start using the Slack slash commands.

You can also select **Reinstall Slack app** to update the app in your Slack workspace
to the latest version. See the [Version history](#version-history) for details.

## Create a project alias for Slack

To create a project alias on GitLab.com for Slack integration:

1. Go to your project's home page.
1. Go to **Settings > Integrations** (only visible on GitLab.com)
1. On the **Integrations** page, select **Slack application**.
1. The current **Project Alias**, if any, is displayed. To edit this value,
   select **Edit**.
1. Enter your desired alias, and select **Save changes**.

Some Slack commands require a project alias, and fail with the following error
if the project alias is incorrect or missing from the command:

```plaintext
GitLab error: project or alias not found
```

## Usage

After confirming the installation, you, and everyone else in your Slack workspace,
can use all the [slash commands](../../../integration/slash_commands.md).

When you perform your first slash command, you are asked to authorize your
Slack user on GitLab.com.

The only difference with the [manually configurable Slack slash commands](slack_slash_commands.md)
is that all the commands should be prefixed with the `/gitlab` keyword.

For example, to show the issue number `1001` under the `gitlab-org/gitlab`
project, you would do:

```plaintext
/gitlab gitlab-org/gitlab issue show 1001
```

## Version history

### 15.0+

In GitLab 15.0 the Slack app is updated to [Slack's new granular permissions app model](https://medium.com/slack-developer-blog/more-precision-less-restrictions-a3550006f9c3).

There is no change in functionality. A reinstall is not required but recommended.

## Troubleshooting

When you work with the Slack app, the
[App Home](https://api.slack.com/start/overview#app_home) might not display properly.
As a workaround, ensure your app is up to date.

To update an existing Slack integration:

1. Go to your [chat settings](https://gitlab.com/-/profile/chat_names).
1. Next to your project, select **Slack application**.
1. Select **Reinstall Slack app**.

Alternatively, you can [configure a new Slack integration](https://about.gitlab.com/solutions/slack/).
