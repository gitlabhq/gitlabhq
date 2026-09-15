---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting GitLab for Slack app
description: "Troubleshooting guide for the GitLab for Slack app. Covers common issues like missing projects and notification problems."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When working with the GitLab for Slack app, you might encounter the following issues.

## App does not appear in the list of integrations

The GitLab for Slack app might not appear in the list of integrations. To have the GitLab for Slack app on your GitLab Self-Managed instance, an administrator must [turn on the integration](../../../administration/settings/slack_app.md). On GitLab.com, the GitLab for Slack app is available by default.

## Error: `Project or alias not found`

Some Slack commands must have a project full path or alias and fail with the following error
if the project cannot be found:

```plaintext
GitLab error: project or alias not found
```

To resolve this issue, ensure:

- The project full path is correct.
- If using a [project alias](gitlab_slack_application.md#create-a-project-alias), the alias is correct.
- The GitLab for Slack app is [turned on for the project](gitlab_slack_application.md#from-the-project-or-group-settings).

## Slash commands return `dispatch_failed` in Slack

Slash commands might return `/gitlab failed with the error "dispatch_failed"` in Slack.

To resolve this issue, ensure an administrator has properly configured the [GitLab for Slack app settings](../../../administration/settings/slack_app.md) on your GitLab Self-Managed instance.

## Notifications not received to a channel

If you're not receiving notifications to a Slack channel, ensure:

- The channel name you configured is correct.
- If the channel is private, you've [added the GitLab for Slack app to the channel](gitlab_slack_application.md#receive-notifications-to-a-private-channel).

## App Home does not display properly

If the [App Home](https://api.slack.com/start/overview#app_home) does not display properly, ensure your [app is up to date](gitlab_slack_application.md#reinstall-the-gitlab-for-slack-app).

## Error: `This alias has already been taken`

You might encounter error `422: The change you requested was rejected` when trying to set up on a new project. The returned Rails error might be:

```plaintext
"exception.message": "Validation failed: Alias This alias has already been taken"
```

To resolve this issue:

1. Search your namespace for projects with similar names that have the GitLab for Slack app turned on.
1. Check among these projects for those with the same alias name as the failed project.
1. Edit the alias, make it different, and try to turn on the GitLab for Slack app for the failed project again.

## GitLab Duo `@mention` failures

When you `@mention` the GitLab app in Slack to trigger GitLab Duo, the app posts a message
back to the thread if something goes wrong.
Use the message text to identify the cause and apply the fix.

| Slack message | Cause | Fix |
|---|---|---|
| Lock emoji (🔒) and an authorization prompt | Your Slack account is not linked to a GitLab account. | Complete the authorization flow to link your Slack and GitLab accounts. |
| `"You do not have access to this feature yet"` | The `slack_duo_agent` feature flag is not enabled for your account. | Ask an administrator to enable the feature flag for your user. |
| `"This feature requires experiment and beta GitLab Duo features to be turned on"` | Experiment and beta GitLab Duo features are turned off. | Turn on [beta and experimental features](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features). On GitLab.com, this setting is for the top-level group. On GitLab Self-Managed and GitLab Dedicated, it is for the instance. |
| `"This feature requires GitLab Duo Agent Platform"` | Your account does not have a GitLab Duo Agent Platform license. | Check your GitLab Duo entitlement with your administrator. |
| `"Set your default Duo namespace in your preferences"` | Your GitLab account has no default GitLab Duo namespace configured. | Set a default GitLab Duo namespace in your GitLab preferences. On GitLab.com, you must have an active GitLab Duo add-on seat in the namespace. |
| `"The Duo Developer flow is not enabled for your namespace"` | The foundational GitLab Duo flow is not turned on for your namespace. | Ask a group owner to turn on the flow in GitLab Duo Agent Platform settings. |
| `"Could not set up the service account…"` | The service account for your namespace could not be provisioned. | Check your namespace GitLab Duo configuration and service account provisioning. |
| `"Could not set up the workspace project…"` | GitLab could not find or create the `duo-workspace` project in your namespace. | Verify that you can create projects in the namespace. Your role and the namespace `project_creation_level` setting must allow project creation. |
| `"Failed to start the Duo Developer workflow"` or `"Something went wrong…"` | The GitLab Duo flow trigger or execution failed. | Check the CI job logs and GitLab integration logs for details. |

### Debugging tips for GitLab Duo `@mention`

- Integration logs are written to `integrations_json.log`. Each entry includes the
  `slack_workspace_id` field, and often `slack_user_id` and `channel_id`. Filter by
  `slack_workspace_id` to find entries relevant to your workspace.
- Sidekiq worker logs (`sidekiq.log`) also include `slack_workspace_id` and `slack_user_id`
  for `Integrations::SlackEventWorker` jobs. Use these to trace whether the event was
  received and processed.
- If the bot cannot react or reply at all, the issue is likely with the Slack integration
  configuration or bot token. Check `integrations_json.log` for entries with
  `"message": "SlackInstallation record has no bot token"`. If the bot reacts but then
  posts an error, the issue is with the user-side authorization gates or namespace resolution.
- The `duo-workspace` project is created automatically the first time a flow runs and reused
  afterward. If project creation fails, use a namespace where you have at least the Maintainer
  role, or ask a group owner to adjust the `project_creation_level` setting.
