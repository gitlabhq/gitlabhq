# Project services

Project services allow you to integrate GitLab with other applications. They
are a bit like plugins in that they allow a lot of freedom in adding
functionality to GitLab.

## Accessing the project services

You can find the available services under the **Integrations** page in your
project's settings.

1. Navigate to the cog icon in the upper right corner of your project. You need
   to have at least [master permission][permissions] on the project.

    ![Accessing the services](img/accessing_integrations.png)

1. There are more than 20 services to integrate with. Click on the one that you
   want to configure.

    ![Project services list](img/project_services.png)

Below, you will find a list of the currently supported ones accompanied with
comprehensive documentation.

## Services

Click on the service links to see further configuration instructions and details.

| Service |	Description |
| ------- | ----------- |
| Asana     |	Asana - Teamwork without email |
| Assembla 	| Project Management Software (Source Commits Endpoint) |
| [Atlassian Bamboo CI](bamboo.md) | A continuous integration and build server |
| Buildkite | Continuous integration and deployments |
| [Builds emails](builds_emails.md) |	Email the builds status to a list of recipients |
| [Bugzilla](bugzilla.md) | Bugzilla issue tracker |
| Campfire | Simple web-based real-time group chat |
| Custom Issue Tracker | Custom issue tracker |
| Drone CI | Continuous Integration platform built on Docker, written in Go |
| [Emails on push](emails_on_push.md) | Email the commits and diff of each push to a list of recipients |
| External Wiki | Replaces the link to the internal wiki with a link to an external wiki |
| Flowdock | Flowdock is a collaboration web app for technical teams |
| Gemnasium | Gemnasium monitors your project dependencies and alerts you about updates and security vulnerabilities |
| [HipChat](hipchat.md) | Private group chat and IM |
| [Irker (IRC gateway)](irker.md) | Send IRC messages, on update, to a list of recipients through an Irker gateway |
| [JIRA](jira.md) | JIRA issue tracker |
| JetBrains TeamCity CI | A continuous integration and build server |
| [Kubernetes](kubernetes.md) | A containerized deployment service |
| [Mattermost slash commands](mattermost_slash_commands.md) | Mattermost chat and ChatOps slash commands |
| [Mattermost Notifications](mattermost.md) | Receive event notifications in Mattermost |
| [Slack Notifications](slack.md) | Receive event notifications in Slack |
| [Slack slash commands](slack_slash_commands.md) | Slack chat and ChatOps slash commands |
| PivotalTracker | Project Management Software (Source Commits Endpoint) |
| Pushover | Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop |
| [Redmine](redmine.md) | Redmine issue tracker |

## Services templates

Services templates is a way to set some predefined values in the Service of
your liking which will then be pre-filled on each project's Service.

Read more about [Services templates in this document](services_templates.md).

## Contributing to project services

Because GitLab is open source we can ship with the code and tests for all
plugins. This allows the community to keep the plugins up to date so that they
always work in newer GitLab versions.

For an overview of what projects services are available, please see the
[project_services source directory][projects-code].

Contributions are welcome!

[projects-code]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/models/project_services
[permissions]: ../../permissions.md
