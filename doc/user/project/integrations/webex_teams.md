# Webex Teams service

You can configure GitLab to send notifications to a Webex Teams space.

## Create a webhook for the space

1. Go to the [Incoming Webhooks app page](https://apphub.webex.com/teams/applications/incoming-webhooks-cisco-systems).
1. Click **Connect** and log in to Webex Teams, if required.
1. Enter a name for the webhook and select the space that will receive the notifications.
1. Click **ADD**.
1. Copy the **Webhook URL**.

## Configure settings in GitLab

Once you have a webhook URL for your Webex Teams space, you can configure GitLab to send notifications.

1. Navigate to **Project > Settings > Integrations**.
1. Select the **Webex Teams** integration.
1. Ensure that the **Active** toggle is enabled.
1. Select the checkboxes corresponding to the GitLab events you want to receive in Webex Teams.
1. Paste the **Webhook** URL for the Webex Teams space.
1. Configure the remaining options and then click **Test settings and save changes**.

The Webex Teams space will begin to receive all applicable GitLab events.
