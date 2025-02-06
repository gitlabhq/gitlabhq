---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pumble
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93623) in GitLab 15.3.

You can configure GitLab to send notifications to a Pumble channel:

1. Create a webhook for the channel.
1. Add the webhook to GitLab.

## Create a webhook for your Pumble channel

1. Follow the steps in [Incoming Webhooks for Pumble](https://pumble.com/help/integrations/add-pumble-apps/incoming-webhooks-for-pumble/) in the Pumble documentation.
1. Copy the webhook URL.

## Configure settings in GitLab

After you have a webhook URL for your Pumble channel, configure GitLab to send
notifications:

1. To enable the integration for your group or project:
   1. In your group or project, on the left sidebar, select **Settings > Integrations**.
1. To enable the integration for your instance:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Settings > Integrations**.
1. Select the **Pumble** integration.
1. Ensure that the **Active** toggle is enabled.
1. Select the checkboxes corresponding to the GitLab events you want to receive in Pumble.
1. Paste the **Webhook** URL for the Pumble channel.
1. Configure the remaining options.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

The Pumble channel begins to receive all applicable GitLab events.
