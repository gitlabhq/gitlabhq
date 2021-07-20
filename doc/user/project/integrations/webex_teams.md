---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Webex Teams service **(FREE)**

You can configure GitLab to send notifications to a Webex Teams space:

1. Create a webhook for the space.
1. Add the webhook to GitLab.

## Create a webhook for the space

1. Go to the [Incoming Webhooks app page](https://apphub.webex.com/applications/incoming-webhooks-cisco-systems-38054).
1. Select **Connect** and log in to Webex Teams, if required.
1. Enter a name for the webhook and select the space to receive the notifications.
1. Select **ADD**.
1. Copy the **Webhook URL**.

## Configure settings in GitLab

Once you have a webhook URL for your Webex Teams space, you can configure GitLab to send
notifications:

1. Navigate to:
   - **Settings > Integrations** in a project to enable the integration at the project level.
   - **Settings > Integrations** in a group to enable the integration at the group level.
   - On the top bar, select **Menu >** **{admin}** **Admin**. Then, in the left sidebar,
     select **Settings > Integrations** to enable an instance-level integration.
1. Select the **Webex Teams** integration.
1. Ensure that the **Active** toggle is enabled.
1. Select the checkboxes corresponding to the GitLab events you want to receive in Webex Teams.
1. Paste the **Webhook** URL for the Webex Teams space.
1. Configure the remaining options and then click **Test settings and save changes**.

The Webex Teams space begins to receive all applicable GitLab events.
