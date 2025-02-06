---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting GitLab for Slack app
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When working with the GitLab for Slack app, you might encounter the following issues.

For administrator documentation, see [GitLab for Slack app administration](../../../administration/settings/slack_app.md#troubleshooting).

## App does not appear in the list of integrations

The GitLab for Slack app might not appear in the list of integrations. To have the GitLab for Slack app on your GitLab Self-Managed instance, an administrator must [enable the integration](../../../administration/settings/slack_app.md). On GitLab.com, the GitLab for Slack app is available by default.

## Error: `Project or alias not found`

Some Slack commands must have a project full path or alias and fail with the following error
if the project cannot be found:

```plaintext
GitLab error: project or alias not found
```

To resolve this issue, ensure:

- The project full path is correct.
- If using a [project alias](gitlab_slack_application.md#create-a-project-alias), the alias is correct.
- The GitLab for Slack app is [enabled for the project](gitlab_slack_application.md#from-the-project-or-group-settings).

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

1. Search in your namespace for projects with similar names and have the GitLab for Slack app enabled.
1. Check among these projects for those with the same alias name as the failed project.
1. Edit the alias, make it different, and retry enabling GitLab for Slack app for the failed project.
