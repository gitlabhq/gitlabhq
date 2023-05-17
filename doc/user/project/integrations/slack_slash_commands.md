---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Slack slash commands **(FREE SELF)**

NOTE:
This feature is only configurable on self-managed GitLab instances.
For GitLab.com, use the [GitLab for Slack app](gitlab_slack_application.md) instead.

If you want to control and view GitLab content while you're
working in Slack, you can use Slack slash commands.
To use Slack slash commands, you must configure both Slack and GitLab.

GitLab can also send events (for example, `issue created`) to Slack as notifications.
The [Slack notifications integration](slack.md) is configured separately.

## Configure GitLab and Slack

Slack slash command integrations
are scoped to a project.

1. In GitLab, on the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Slack slash commands**. Leave this browser tab open.
1. Open a new browser tab, sign in to your Slack team, and [start a new Slash Commands integration](https://my.slack.com/services/new/slash-commands).
1. Enter a trigger command. We suggest you use the project name.
   Select **Add Slash Command Integration**.
1. Complete the rest of the fields in the Slack configuration page using information from the GitLab browser tab.
   In particular, make sure you copy and paste the **URL**.

   ![Slack setup instructions](img/slack_setup.png)

1. On the Slack configuration page, select **Save Integration** and copy the **Token**.
1. Go back to the GitLab configuration page and paste in the **Token**.
1. Ensure the **Active** checkbox is selected and select **Save changes**.

## Slash commands

You can now use the available [Slack slash commands](../../../integration/slash_commands.md).
