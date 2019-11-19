# GitLab Slack application **(FREE ONLY)**

NOTE: **Note:**
The GitLab Slack application is only configurable for GitLab.com. It will **not**
work for on-premises installations where you can configure the
[Slack slash commands](slack_slash_commands.md) service instead. We're working
with Slack on making this configurable for all GitLab installations, but there's
no ETA.
It was first introduced in GitLab 9.4 and distributed to Slack App Directory in
GitLab 10.2.

Slack provides a native application which you can enable via your project's
integrations on GitLab.com.

## Slack App Directory

The simplest way to enable the GitLab Slack application for your workspace is to
install the [GitLab application](https://slack-platform.slack.com/apps/A676ADMV5-gitlab) from
the [Slack App Directory](https://slack.com/apps).

Clicking install will take you to the
[GitLab Slack application landing page](https://gitlab.com/profile/slack/edit)
where you can select a project to enable the GitLab Slack application for.

![GitLab Slack application landing page](img/gitlab_slack_app_landing_page.png)

## Configuration

Alternatively, you can configure the Slack application with a project's
integration settings.

Keep in mind that you need to have the appropriate permissions for your Slack
team in order to be able to install a new application, read more in Slack's
docs on [Adding an app to your team](https://slack.com/help/articles/202035138).

To enable GitLab's service for your Slack team:

1. Go to your project's **Settings > Integration > Slack application** (only
   visible on GitLab.com)
1. Click the "Add to Slack" button

That's all! You can now start using the Slack slash commands.

## Usage

After confirming the installation, you, and everyone else in your Slack team,
can use all the [slash commands].

When you perform your first slash command you will be asked to authorize your
Slack user on GitLab.com.

The only difference with the [manually configurable Slack slash commands][slack-manual]
is that all the commands should be prefixed with the `/gitlab` keyword.
We are working on making this configurable in the future.

For example, to show the issue number `1001` under the `gitlab-org/gitlab`
project, you would do:

```
/gitlab gitlab-org/gitlab issue show 1001
```

[slash commands]: ../../../integration/slash_commands.md
[slack-manual]: slack_slash_commands.md
