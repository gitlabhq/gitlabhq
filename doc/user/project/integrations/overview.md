# Integrations

Integrations allow you to integrate GitLab with other applications. They
are a bit like plugins in that they allow a lot of freedom in adding
functionality to GitLab.

## Accessing integrations

You can find the available integrations under your project's
**Settings ➔ Integrations** page.

There are more than 20 integrations to integrate with. Click on the one that you
want to configure.

![Integrations list](img/project_services.png)

Below, you will find a list of the currently supported ones accompanied with comprehensive documentation.

## Integrations listing

Click on the service links to see further configuration instructions and details.

| Service | Description | Service Hooks |
| ------- | ----------- | ------------- |
| Asana     | Asana - Teamwork without email | No |
| Assembla | Project Management Software (Source Commits Endpoint) | No |
| [Atlassian Bamboo CI](bamboo.md) | A continuous integration and build server | Yes |
| Buildkite | Continuous integration and deployments | Yes |
| [Bugzilla](bugzilla.md) | Bugzilla issue tracker | No |
| Campfire | Simple web-based real-time group chat | No |
| Custom Issue Tracker | Custom issue tracker | No |
| [Discord Notifications](discord_notifications.md) | Receive event notifications in Discord | No |
| Drone CI | Continuous Integration platform built on Docker, written in Go | Yes |
| [Emails on push](emails_on_push.md) | Email the commits and diff of each push to a list of recipients | No |
| External Wiki | Replaces the link to the internal wiki with a link to an external wiki | No |
| Flowdock | Flowdock is a collaboration web app for technical teams | No |
| [Generic alerts](generic_alerts.md) **(ULTIMATE)** | Receive alerts on GitLab from any source | No |
| [GitHub](github.md) **(PREMIUM)** | Sends pipeline notifications to GitHub | No |
| [Hangouts Chat](hangouts_chat.md) | Receive events notifications in Google Hangouts Chat | No |
| [HipChat](hipchat.md) | Private group chat and IM | No |
| [Irker (IRC gateway)](irker.md) | Send IRC messages, on update, to a list of recipients through an Irker gateway | No |
| [Jira](jira.md) | Jira issue tracker | No |
| [Jenkins](../../../integration/jenkins.md) **(STARTER)** | An extendable open source continuous integration server | Yes |
| JetBrains TeamCity CI | A continuous integration and build server | Yes |
| [Mattermost slash commands](mattermost_slash_commands.md) | Mattermost chat and ChatOps slash commands | No |
| [Mattermost Notifications](mattermost.md) | Receive event notifications in Mattermost | No |
| [Microsoft teams](microsoft_teams.md) |  Receive notifications for actions that happen on GitLab into a room on Microsoft Teams using Office 365 Connectors | No |
| Packagist | Update your project on Packagist, the main Composer repository | Yes |
| Pipelines emails | Email the pipeline status to a list of recipients | No |
| [Slack Notifications](slack.md) | Send GitLab events (for example, an issue was created) to Slack as notifications | No |
| [Slack slash commands](slack_slash_commands.md) **(CORE ONLY)** | Use slash commands in Slack to control GitLab | No |
| [GitLab Slack application](gitlab_slack_application.md) **(FREE ONLY)** | Use Slack's official application | No |
| PivotalTracker | Project Management Software (Source Commits Endpoint) | No |
| [Prometheus](prometheus.md) | Monitor the performance of your deployed apps | No |
| Pushover | Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop | No |
| [Redmine](redmine.md) | Redmine issue tracker | No |
| [Unify Circuit](unify_circuit.md) | Receive events notifications in Unify Circuit | No |
| [YouTrack](youtrack.md) | YouTrack issue tracker | No |

## Push hooks limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17874) in GitLab 12.4.

If a single push includes changes to more than three branches or tags, services
supported by `push_hooks` and `tag_push_hooks` events won't be executed.

The number of branches or tags supported can be changed via
[`push_event_hooks_limit` application setting](../../../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls).

## Services templates

Services templates is a way to set some predefined values in the Service of
your liking which will then be pre-filled on each project's Service.

Read more about [Services templates in this document](services_templates.md).

## Troubleshooting integrations

Some integrations use service hooks for integration with external applications. To confirm which ones use service hooks, see the [integrations listing](#integrations-listing). GitLab stores details of service hook requests made within the last 2 days. To view details of the requests, go to the service's configuration page.

The **Recent Deliveries** section lists the details of each request made within the last 2 days:

- HTTP status code (green for 200-299 codes, red for the others, `internal error` for failed deliveries)
- Triggered event
- URL to which the request was sent
- Elapsed time of the request
- Relative time in which the request was made

To view more information about the request's execution, click the respective **View details** link.
On the details page, you can see the data sent by GitLab (request headers and body) and the data received by GitLab (response headers and body).

From this page, you can repeat delivery with the same data by clicking **Resend Request**.

![Recent deliveries](img/webhook_logs.png)

### Uninitialized repositories

Some integrations fail with an error `Test Failed. Save Anyway` when you attempt to set them up on
uninitialized repositories. This is because the default service test uses push data to build the
payload for the test request, and it fails, because there are no push events for the project.

To resolve this error, initialize the repository by pushing a test file to the project and set up
the integration again.

## Contributing to integrations

Because GitLab is open source we can ship with the code and tests for all
plugins. This allows the community to keep the plugins up to date so that they
always work in newer GitLab versions.

For an overview of what integrations are available, please see the
[project_services source directory](https://gitlab.com/gitlab-org/gitlab/tree/master/app/models/project_services).

Contributions are welcome!
