# Slack Notifications Service

The Slack Notifications Service allows your GitLab project to send events (e.g. issue created) to your existing Slack team as notifications. This requires configurations in both Slack and GitLab.

> Note: You can also use Slack slash commands to control GitLab inside Slack. This is the separately configured [Slack slash commands](slack_slash_commands.md).

## Slack Configuration

1. Sign in to your Slack team and [start a new Incoming WebHooks configuration](https://my.slack.com/services/new/incoming-webhook/).
1. Select the Slack channel where notifications will be sent to by default. Click the **Add Incoming WebHooks integration** button to add the configuration.
1. Copy the **Webhook URL**, which we'll use later in the GitLab configuration.

## GitLab Configuration

1. Navigate to the [Integrations page](project_services.md#accessing-the-project-services) in your project's settings, i.e. **Project > Settings > Integrations**.
1. Select the **Slack notifications** project service to configure it.
1. Check the **Active** checkbox to turn on the service.
1. Check the checkboxes corresponding to the GitLab events you want to send to Slack as a notification.
1. For each event, optionally enter the Slack channel where you want to send the event. (Do _not_ include the `#` symbol.) If left empty, the event will be sent to the default channel that you configured in the Slack Configuration step.
1. Paste the **Webhook URL** that you copied from the Slack Configuration step.
1. Optionally customize the Slack bot username that will be sending the notifications.
1. Configure the remaining options and click `Save changes`.

Your Slack team will now start receiving GitLab event notifications as configured.

![Slack configuration](img/slack_configuration.png)