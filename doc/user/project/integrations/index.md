---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project integrations **(FREE)**

You can integrate your GitLab projects with other applications. Integrations are
like plugins, and give you the freedom to add
functionality to GitLab.

## View project integrations

Prerequisites:

- You must have at least the Maintainer role for the project.

To view the available integrations for your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.

You can also view and manage integration settings across [all projects in an instance or group](../../admin_area/settings/project_integration_management.md).
For a single project, you can choose to inherit the instance or group configuration,
or provide custom settings.

NOTE:
Instance and group-based integration management replaces service templates, which
were [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/268032) in GitLab 14.0.

## Manage SSL verification

By default, the SSL certificate for outgoing HTTP requests is verified based on
an internal list of Certificate Authorities. This means the certificate cannot
be self-signed.

You can turn off SSL verification in the configuration settings for [webhooks](webhooks.md#configure-a-webhook-in-gitlab)
and some integrations.

## Available integrations

You can configure the following integrations.

| Integration                                                                 | Description                                                           | Integration hooks      |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------|------------------------|
| [Asana](asana.md)                                                           | Add commit messages as comments to Asana tasks.                       | **{dotted-circle}** No |
| Assembla                                                                    | Manage projects.                                                      | **{dotted-circle}** No |
| [Atlassian Bamboo CI](bamboo.md)                                            | Run CI/CD pipelines with Atlassian Bamboo.                            | **{check-circle}** Yes |
| [Bugzilla](bugzilla.md)                                                     | Use Bugzilla as the issue tracker.                                    | **{dotted-circle}** No |
| Buildkite                                                                   | Run CI/CD pipelines with Buildkite.                                   | **{check-circle}** Yes |
| Campfire                                                                    | Connect to chat.                                                      | **{dotted-circle}** No |
| [Confluence Workspace](../../../api/integrations.md#confluence-integration) | Use Confluence Cloud Workspace as an internal wiki.                   | **{dotted-circle}** No |
| [Custom issue tracker](custom_issue_tracker.md)                             | Use a custom issue tracker.                                           | **{dotted-circle}** No |
| [Datadog](../../../integration/datadog.md)                                  | Trace your GitLab pipelines with Datadog.                             | **{check-circle}** Yes |
| [Discord Notifications](discord_notifications.md)                           | Send notifications about project events to a Discord channel.         | **{dotted-circle}** No |
| Drone CI                                                                    | Run CI/CD pipelines with Drone.                                       | **{check-circle}** Yes |
| [Emails on push](emails_on_push.md)                                         | Send commits and diff of each push by email.                          | **{dotted-circle}** No |
| [EWM](ewm.md)                                                               | Use IBM Engineering Workflow Management as the issue tracker.         | **{dotted-circle}** No |
| [External wiki](../wiki/index.md#link-an-external-wiki)                     | Link an external wiki.                                                | **{dotted-circle}** No |
| [GitHub](github.md)                                                         | Obtain statuses for commits and pull requests.                        | **{dotted-circle}** No |
| [Google Chat](hangouts_chat.md)                                             | Send notifications from your GitLab project to a room in Google Chat. | **{dotted-circle}** No |
| [Harbor](harbor.md)                                                         | Use Harbor as the container registry.                                 | **{dotted-circle}** No |
| [irker (IRC gateway)](irker.md)                                             | Send IRC messages.                                                    | **{dotted-circle}** No |
| [Jenkins](../../../integration/jenkins.md)                                  | Run CI/CD pipelines with Jenkins.                                     | **{check-circle}** Yes |
| JetBrains TeamCity CI                                                       | Run CI/CD pipelines with TeamCity.                                    | **{check-circle}** Yes |
| [Jira](../../../integration/jira/index.md)                                  | Use Jira as the issue tracker.                                        | **{dotted-circle}** No |
| [Mattermost notifications](mattermost.md)                                   | Send notifications about project events to Mattermost channels.       | **{dotted-circle}** No |
| [Mattermost slash commands](mattermost_slash_commands.md)                   | Perform common tasks with slash commands.                             | **{dotted-circle}** No |
| [Microsoft Teams notifications](microsoft_teams.md)                         | Receive event notifications.                                          | **{dotted-circle}** No |
| Packagist                                                                   | Keep your PHP dependencies updated on Packagist.                      | **{check-circle}** Yes |
| [Pipelines emails](pipeline_status_emails.md)                               | Send the pipeline status to a list of recipients by email.            | **{dotted-circle}** No |
| [Pivotal Tracker](pivotal_tracker.md)                                       | Add commit messages as comments to Pivotal Tracker stories.           | **{dotted-circle}** No |
| [Prometheus](prometheus.md)                                                 | Monitor application metrics.                                          | **{dotted-circle}** No |
| [Pumble](pumble.md)                                                         | Send event notifications to a Pumble channel.                         | **{dotted-circle}** No |
| Pushover                                                                    | Get real-time notifications on your device.                           | **{dotted-circle}** No |
| [Redmine](redmine.md)                                                       | Use Redmine as the issue tracker.                                     | **{dotted-circle}** No |
| [Shimo Workspace](shimo.md)                                                 | Use Shimo instead of the GitLab Wiki.                                 | **{dotted-circle}** No |
| [GitLab for Slack app](gitlab_slack_application.md)                         | Use Slack's official GitLab application.                              | **{dotted-circle}** No |
| [Slack notifications](slack.md)                                             | Send notifications about project events to Slack.                     | **{dotted-circle}** No |
| [Slack slash commands](slack_slash_commands.md)                             | Enable slash commands in a workspace.                                 | **{dotted-circle}** No |
| [Squash TM](squash_tm.md)                                                   | Update Squash TM requirements when GitLab issues are modified.        | **{check-circle}** Yes |
| [Unify Circuit](unify_circuit.md)                                           | Send notifications about project events to Unify Circuit.             | **{dotted-circle}** No |
| [Webex Teams](webex_teams.md)                                               | Receive events notifications.                                         | **{dotted-circle}** No |
| [YouTrack](youtrack.md)                                                     | Use YouTrack as the issue tracker.                                    | **{dotted-circle}** No |
| [ZenTao](zentao.md)                                                         | Use ZenTao as the issue tracker.                                      | **{dotted-circle}** No |

### Project webhooks

You can configure a project webhook to listen for specific events
like pushes, issues, or merge requests. When the webhook is triggered, GitLab
sends a POST request with data to a specified webhook URL.

For more information, see [Webhooks](webhooks.md).

## Push hooks limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17874) in GitLab 12.4.

If a single push includes changes to more than three branches or tags, integrations
supported by `push_hooks` and `tag_push_hooks` events aren't executed.

You can change the number of supported branches or tags by changing the
[`push_event_hooks_limit` application setting](../../../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls).

## Contribute to integrations

If you're interested in developing a new native integration for GitLab, see:

- [Integrations development guidelines](../../../development/integrations/index.md)
- [GitLab Developer Portal](https://developer.gitlab.com)

## Troubleshooting

Some integrations use hooks to integrate with external applications. To confirm which ones use integration hooks, see the [available integrations](#available-integrations). For more information, see [webhook troubleshooting](webhooks.md#troubleshooting).

### `Test Failed. Save Anyway` error

Some integrations fail with an error `Test Failed. Save Anyway` when you set them
up on uninitialized repositories. This error occurs because the integration uses
push data to build the test payload, and there are no push events in the project.

To resolve this error, initialize the repository by pushing a test file to the project
and set up the integration again.
