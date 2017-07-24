# GitLab Slack application

>**Notes:**
- Introduced in [GitLab Enterprise Edition] 9.4.
- Currently only configurable for GitLab.com, it will not work for on-premises
  installations. You can configure the [Slack slash commands](slack_slash_commands.md)
  service instead. We're working with Slack on making this configurable for all
  GitLab installations.

Slack provides a native application which you can enable via your project's
integrations on GitLab.com.

## Configuration

Keep in mind that you need to have the appropriate permissions for your Slack
team in order to be able to install a new application, read more in Slack's
docs on [Adding an app to your team][slack-docs].

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

For example, to show the issue number `1001` under the `gitlab-org/gitlab-ce`
project, you would do:

```
/gitlab gitlab-org/gitlab-ce issue show 1001
```

[slack-docs]: https://get.slack.help/hc/en-us/articles/202035138-Adding-apps-to-your-team
[slash commands]: ../../../integration/slash_commands.md
[slack-manual]: slack_slash_commands.md
