---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab for Slack app administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358872) for GitLab Self-Managed in GitLab 16.2.

NOTE:
This page contains administrator documentation for the GitLab for Slack app. For user documentation, see [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md).

The GitLab for Slack app distributed through the Slack App Directory only works with GitLab.com.
On GitLab Self-Managed, you can create your own copy of the GitLab for Slack app from a [manifest file](https://api.slack.com/reference/manifests#creating_apps) and configure your instance.

The app is a private one-time copy installed in your Slack workspace only and not distributed through the Slack App Directory. To have the [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md) on your GitLab Self-Managed instance, you must enable the integration.

## Create a GitLab for Slack app

Prerequisites:

- You must be at least a [Slack workspace administrator](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack).

To create a GitLab for Slack app:

- **In GitLab**:

  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **GitLab for Slack app**.
  1. Select **Create Slack app**.

You're then redirected to Slack for the next steps.

- **In Slack**:

  1. Select the Slack workspace to create the app in, then select **Next**.
  1. Slack displays a summary of the app for review. To view the complete manifest, select **Edit Configurations**. To go back to the review summary, select **Next**.
  1. Select **Create**.
  1. Select **Got it** to close the dialog.
  1. Select **Install to Workspace**.

## Configure the settings

After you've [created a GitLab for Slack app](#create-a-gitlab-for-slack-app), you can configure the settings in GitLab:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **GitLab for Slack app**.
1. Select the **Enable GitLab for Slack app** checkbox.
1. Enter the details of your GitLab for Slack app:
   1. Go to [Slack API](https://api.slack.com/apps).
   1. Search for and select **GitLab (\<your host name\>)**.
   1. Scroll to **App Credentials**.
1. Select **Save changes**.

### Test your configuration

To test your GitLab for Slack app configuration:

1. Enter the `/gitlab help` slash command into a channel in your Slack workspace.
1. Press <kbd>Enter</kbd>.

You should see a list of available Slash commands.

To use Slash commands for a project, configure the [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md) for the project.

## Install the GitLab for Slack app

> - Installation for a specific instance [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/391526) in GitLab 16.10 [with a flag](../feature_flags.md) named `gitlab_for_slack_app_instance_and_group_level`. Disabled by default.
> - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820) in GitLab 16.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803) in GitLab 17.8. Feature flag `gitlab_for_slack_app_instance_and_group_level` removed.

Prerequisites:

- You must have the [appropriate permissions to add apps to your Slack workspace](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).
- You must [create a GitLab for Slack app](#create-a-gitlab-for-slack-app) and [configure the app settings](#configure-the-settings).

To install the GitLab for Slack app from the instance settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.
1. Select **GitLab for Slack app**.
1. Select **Install GitLab for Slack app**.
1. On the Slack confirmation page, select **Allow**.

## Update the GitLab for Slack app

Prerequisites:

- You must be at least a [Slack workspace administrator](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack).

When GitLab releases new features for the GitLab for Slack app, you might have to manually update your copy to use the new features.

To update your copy of the GitLab for Slack app:

- **In GitLab**:

  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **GitLab for Slack app**.
  1. Select **Download latest manifest file** to download `slack_manifest.json`.

- **In Slack**:

  1. Go to [Slack API](https://api.slack.com/apps).
  1. Search for and select **GitLab (\<your host name\>)**.
  1. On the left sidebar, select **App Manifest**.
  1. Select the **JSON** tab to switch to a JSON view of the manifest.
  1. Copy the contents of the `slack_manifest.json` file you've downloaded from GitLab.
  1. Paste the contents into the JSON viewer to replace any existing contents.
  1. Select **Save Changes**.

## Connectivity requirements

To enable the GitLab for Slack app functionality, your network must allow inbound and outbound connections between GitLab and Slack.

- For [Slack notifications](../../user/project/integrations/gitlab_slack_application.md#slack-notifications), the GitLab instance must be able to send requests to `https://slack.com`.
- For [Slash commands](../../user/project/integrations/gitlab_slack_application.md#slash-commands) and other features, the GitLab instance must be able to receive requests from `https://slack.com`.

## Troubleshooting

When administering the GitLab for Slack app, you might encounter the following issues.

For user documentation, see [GitLab for Slack app](../../user/project/integrations/gitlab_slack_app_troubleshooting.md).

### Slash commands return `dispatch_failed` in Slack

Slash commands might return `/gitlab failed with the error "dispatch_failed"` in Slack.

To resolve this issue, ensure:

- The GitLab for Slack app is properly [configured](#configure-the-settings) and the **Enable GitLab for Slack app** checkbox is selected.
- Your GitLab instance [allows requests to and from Slack](#connectivity-requirements).
