# Project Services

Project services allow you to integrate GitLab with other applications. Below
is list of the currently supported ones.

You can find these within GitLab in the Services page under Project Settings if
you are at least a master on the project.
Project Services are a bit like plugins in that they allow a lot of freedom in
adding functionality to GitLab. For example there is also a service that can
send an email every time someone pushes new commits.

Because GitLab is open source we can ship with the code and tests for all
plugins. This allows the community to keep the plugins up to date so that they
always work in newer GitLab versions.

For an overview of what projects services are available without logging in,
please see the [project_services directory][projects-code].

[projects-code]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/models/project_services

Click on the service links to see
further configuration instructions and details. Contributions are welcome.

## Services

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
| PivotalTracker | Project Management Software (Source Commits Endpoint) |
| Pushover | Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop |
| [Redmine](redmine.md) | Redmine issue tracker |
| [Slack](slack.md) | A team communication tool for the 21st century |

## Services Templates

Services templates is a way to set some predefined values in the Service of
your liking which will then be pre-filled on each project's Service.

Read more about [Services Templates in this document](services_templates.md).
