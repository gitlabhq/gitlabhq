---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project integrations
description: "User documentation for project and group integrations. Includes a list of available integrations."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

This page contains user documentation for project integrations. For administrator documentation, see [Project integration administration](../../../administration/settings/project_integration_management.md).

{{< /alert >}}

You can integrate with external applications to add functionality to GitLab.

You can view and manage integrations for the:

- [Instance](../../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration) (GitLab Self-Managed)
- [Group](#manage-group-default-settings-for-a-project-integration)

You can use:

- [Instance or group default settings for a project integration](#use-instance-or-group-default-settings-for-a-project-integration)
- [Custom settings for a project or group integration](#use-custom-settings-for-a-project-or-group-integration)

## Manage group default settings for a project integration

Prerequisites:

- You must have the Owner role for the group.

To manage the group default settings for a project integration:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select an integration.
1. Complete the fields.
1. Select **Save changes**.

{{< alert type="warning" >}}

This may affect all or most of the subgroups and projects belonging to the group. Review the details below.

{{< /alert >}}

If this is the first time you are setting up group settings for an integration:

- The integration is enabled for all subgroups and projects belonging to the group that don't already have
  this integration configured, if you have the **Enable integration** toggle turned on in the group settings.
- Subgroups and projects that already have the integration configured are not affected, but can choose to use
  the inherited settings at any time.

When you make further changes to the group defaults:

- They are immediately applied to all subgroups and projects belonging to the group that have the integration
  set to use default settings.
- They are immediately applied to newer subgroups and projects, even those created after you last saved defaults for the
  integration. If your group default setting has the **Enable integration** toggle turned on,
  the integration is automatically enabled for all such subgroups and projects.
- Subgroups and projects with custom settings selected for the integration are not immediately affected and
  may choose to use the latest defaults at any time.

If [instance settings](../../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration)
have also been configured for the same integration, projects in the group inherit settings from the group.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

### Remove a group default setting

Prerequisites:

- You must have the Owner role for the group.

To remove a group default setting:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select an integration.
1. Select **Reset** and confirm.

Resetting a group default setting removes integrations that use default settings and belong to a project or subgroup of the group.

## Use instance or group default settings for a project integration

Prerequisites:

- You must have at least the Maintainer role for the project.

To use instance or group default settings for a project integration:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select an integration.
1. On the right, from the dropdown list, select **Use default settings**.
1. Under **Enable integration**, ensure the **Active** checkbox is selected.
1. Complete the fields.
1. Select **Save changes**.

## Use custom settings for a project or group integration

Prerequisites:

- You must have at least the Maintainer role for the project integration.
- You must have the Owner role for the group integration.

To use custom settings for a project or group integration:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Integrations**.
1. Select an integration.
1. On the right, from the dropdown list, select **Use custom settings**.
1. Under **Enable integration**, ensure the **Active** checkbox is selected.
1. Complete the fields.
1. Select **Save changes**.

## Available integrations

The following integrations can be available on a GitLab instance.
If an instance administrator has configured an [integration allowlist](../../../administration/settings/project_integration_management.md#integration-allowlist),
only those integrations are available.

### CI/CD

| Integration                                                  | Description                                                                              | Integration hooks |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Atlassian Bamboo](bamboo.md)                                | Run CI/CD pipelines with Atlassian Bamboo.                                               | {{< icon name="check-circle" >}} Yes |
| Buildkite                                                    | Run CI/CD pipelines with Buildkite.                                                      | {{< icon name="check-circle" >}} Yes |
| Drone                                                        | Run CI/CD pipelines with Drone.                                                          | {{< icon name="check-circle" >}} Yes |
| [Jenkins](../../../integration/jenkins.md)                   | Run CI/CD pipelines with Jenkins.                                                        | {{< icon name="check-circle" >}} Yes |
| JetBrains TeamCity                                           | Run CI/CD pipelines with TeamCity.                                                       | {{< icon name="check-circle" >}} Yes |

### Event notifications

| Integration                                                  | Description                                                                              | Integration hooks |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| Campfire                                                     | Connect Campfire to chat.                                                                | {{< icon name="dotted-circle" >}} No |
| [Discord Notifications](discord_notifications.md)            | Send notifications about project events to a Discord channel.                            | {{< icon name="dotted-circle" >}} No |
| [Google Chat](hangouts_chat.md)                              | Send notifications from your GitLab project to a space in Google Chat.                   | {{< icon name="dotted-circle" >}} No |
| [irker (IRC gateway)](irker.md)                              | Send event notifications to IRC channels.                                                                       | {{< icon name="dotted-circle" >}} No |
| [Matrix notifications](matrix.md)                            | Send notifications about project events to Matrix.                                       | {{< icon name="dotted-circle" >}} No |
| [Mattermost notifications](mattermost.md)                    | Send notifications about project events to Mattermost channels.                          | {{< icon name="dotted-circle" >}} No |
| [Microsoft Teams notifications](microsoft_teams.md)          | Send event notifications to Microsoft Teams.                                          | {{< icon name="dotted-circle" >}} No |
| [Pumble](pumble.md)                                          | Send event notifications to a Pumble channel.                                            | {{< icon name="dotted-circle" >}} No |
| Pushover                                                     | Send event notifications to your device.                                              | {{< icon name="dotted-circle" >}} No |
| [Telegram](telegram.md)                                      | Send notifications about project events to Telegram.                                     | {{< icon name="dotted-circle" >}} No |
| [Unify Circuit](unify_circuit.md)                            | Send notifications about project events to Unify Circuit.                                | {{< icon name="dotted-circle" >}} No |
| [Webex Teams](webex_teams.md)                                | Send event notifications to Webex Teams.                                              | {{< icon name="dotted-circle" >}} No |

### Stores

| Integration                                                  | Description                                                                              | Integration hooks |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Apple App Store Connect](apple_app_store.md)                | Use GitLab to build and release an app in the Apple App Store.                           | {{< icon name="dotted-circle" >}} No |
| [Google Play](google_play.md)                                | Use GitLab to build and release an app in Google Play.                                   | {{< icon name="dotted-circle" >}} No |
| [Harbor](harbor.md)                                          | Use Harbor as the container registry for GitLab.                                         | {{< icon name="dotted-circle" >}} No |
| Packagist                                                    | Update your PHP dependencies in Packagist.                                               | {{< icon name="check-circle" >}} Yes |

### External issue trackers

The following integrations add links to [external issue trackers](../../../integration/external-issue-tracker.md) on the left sidebar in your project.

| Integration                                                  | Description                                                                              | Integration hooks | Issue sync | Can create new issues |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |----------------- |----------------- |
| [Bugzilla](bugzilla.md)                                      | Use Bugzilla as an issue tracker.                                                        | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [ClickUp](clickup.md)                                        | Use ClickUp as an issue tracker.                                                         | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| [Custom issue tracker](custom_issue_tracker.md)              | Use a custom issue tracker.                                                              | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| [Engineering Workflow Management (EWM)](ewm.md)              | Use EWM as an issue tracker.                                                             | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Linear](linear.md)                                          | Use Linear as an issue tracker.                                                          | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| [Phorge](phorge.md)                                          | Use Phorge as an issue tracker.                                                          | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [Redmine](redmine.md)                                        | Use Redmine as an issue tracker.                                                         | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| [YouTrack](youtrack.md)                                      | Use JetBrains YouTrack as your project's issue tracker.                                  | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No |

### External wikis

The following integrations add links to external wikis on the left sidebar in your project.

| Integration                                                  | Description                                                                              | Integration hooks |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Confluence Workspace](confluence.md)                        | Use Confluence Cloud Workspace as an internal wiki.                                      | {{< icon name="dotted-circle" >}} No |
| [External wiki](../wiki/_index.md#link-an-external-wiki)      | Link an external wiki.                                                                   | {{< icon name="dotted-circle" >}} No |

### Other

| Integration                                                  | Description                                                                              | Integration hooks |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ----------------- |
| [Asana](asana.md)                                            | Add commit messages as comments to Asana tasks.                                          | {{< icon name="dotted-circle" >}} No |
| Assembla                                                     | Manage projects with Assembla.                                                           | {{< icon name="dotted-circle" >}} No |
| [Beyond Identity](beyond_identity.md)                        | Verify that GPG keys are authorized by Beyond Identity Authenticator.                    | {{< icon name="dotted-circle" >}} No |
| [Datadog](../../../integration/datadog.md)                   | Trace your GitLab pipelines with Datadog.                                                | {{< icon name="check-circle" >}} Yes |
| [Diffblue Cover](../../../integration/diffblue_cover.md)     | Automatically write comprehensive, human-like Java unit tests.                           | {{< icon name="check-circle" >}} No |
| [Emails on push](emails_on_push.md)                          | Send commits and diffs on push by email.                                                 | {{< icon name="dotted-circle" >}} No |
| [GitGuardian](git_guardian.md)                               | Reject commits based on GitGuardian policies.                                            | {{< icon name="dotted-circle" >}} No |
| [GitHub](github.md)                                          | Receive statuses for commits and pull requests.                                          | {{< icon name="dotted-circle" >}} No |
| [GitLab for Slack app](gitlab_slack_application.md)          | Use the native Slack app to receive notifications and run commands.                      | {{< icon name="dotted-circle" >}} No |
| [Google Artifact Management](google_artifact_management.md)  | Manage your artifacts in Google Artifact Registry.                                       | {{< icon name="dotted-circle" >}} No |
| [Google Cloud IAM](../../../integration/google_cloud_iam.md) | Manage permissions for Google Cloud resources with Identity and Access Management (IAM). | {{< icon name="dotted-circle" >}} No |
| [Jira](../../../integration/jira/_index.md)                  | Use Jira as an issue tracker.                                                            | {{< icon name="dotted-circle" >}} No |
| [Mattermost slash commands](mattermost_slash_commands.md)    | Run slash commands from a Mattermost chat environment.                                   | {{< icon name="dotted-circle" >}} No |
| [Pipeline status emails](pipeline_status_emails.md)          | Send the pipeline status to a list of recipients by email.                               | {{< icon name="dotted-circle" >}} No |
| [Pivotal Tracker](pivotal_tracker.md)                        | Add commit messages as comments to Pivotal Tracker stories.                              | {{< icon name="dotted-circle" >}} No |
| [Slack slash commands](slack_slash_commands.md)              | Run slash commands from a Slack chat environment.                                        | {{< icon name="dotted-circle" >}} No |
| [Squash TM](squash_tm.md)                                    | Update Squash TM requirements when GitLab issues are modified.                           | {{< icon name="check-circle" >}} Yes |

## Project webhooks

Some integrations use [webhooks](webhooks.md) for external applications.

You can configure a project webhook to listen for specific events
like pushes, issues, or merge requests. When the webhook is triggered,
GitLab sends a POST request with data to a specified webhook URL.

For a list of integrations that use webhooks, see [Available integrations](#available-integrations).

## Push hook limit

If a single push includes changes to more than three branches or tags, integrations
supported by `push_hooks` and `tag_push_hooks` events are not executed.

To change the number of supported branches or tags, configure the
[`push_event_hooks_limit` setting](../../../api/settings.md#available-settings).

## SSL verification

By default, the SSL certificate for outgoing HTTP requests is verified based on
an internal list of certificate authorities. The SSL certificate cannot
be self-signed.

You can disable SSL verification when you configure
[webhooks](webhooks.md#configure-webhooks) and some integrations.

## Related topics

- [Integrations API](../../../api/project_integrations.md)
- [GitLab Developer Portal](https://developer.gitlab.com)
