---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Slack slash commands **(FREE SELF)**

NOTE:
This feature is only configurable on self-managed GitLab instances.
For GitLab.com, use the [GitLab for Slack app](gitlab_slack_application.md) instead.

You can use [slash commands](gitlab_slack_application.md#slash-commands) to run common GitLab operations,
like creating an issue, from a [Slack](https://slack.com/) chat environment.
To use slash commands in Slack, you must configure both Slack and GitLab.

GitLab can also send events (such as `issue created`) to Slack as part of the
separately configured [Slack notifications](slack.md).

For a list of available slash commands, see [Slash commands](gitlab_slack_application.md#slash-commands).

## Configure the integration

Slack slash commands are scoped to a project. To configure Slack slash commands:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > Integrations**.
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
