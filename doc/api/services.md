# Services API

>**Note:** This API requires an access token with Master or Owner permissions

## Asana

Asana - Teamwork without email

### Create/Edit Asana service

Set Asana service for a project.

> This service adds commit messages as comments to Asana tasks. Once enabled, commit messages are checked for Asana task URLs (for example, `https://app.asana.com/0/123456/987654`) or task IDs starting with # (for example, `#987654`). Every task ID found will get the commit comment added to it.  You can also close a task with a message containing: `fix #123456`.  You can find your Api Keys here: https://asana.com/developers/documentation/getting-started/auth#api-key

```
PUT /projects/:id/services/asana
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | true | User API token. User must have access to task, all comments will be attributed to this user. |
| `restrict_to_branch` | string | false | Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches. |

### Delete Asana service

Delete Asana service for a project.

```
DELETE /projects/:id/services/asana
```

### Get Asana service settings

Get Asana service settings for a project.

```
GET /projects/:id/services/asana
```

## Assembla

Project Management Software (Source Commits Endpoint)

### Create/Edit Assembla service

Set Assembla service for a project.

```
PUT /projects/:id/services/assembla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | The authentication token
| `subdomain` | string | false | The subdomain setting |

### Delete Assembla service

Delete Assembla service for a project.

```
DELETE /projects/:id/services/assembla
```

### Get Assembla service settings

Get Assembla service settings for a project.

```
GET /projects/:id/services/assembla
```

## Atlassian Bamboo CI

A continuous integration and build server

### Create/Edit Atlassian Bamboo CI service

Set Atlassian Bamboo CI service for a project.

> You must set up automatic revision labeling and a repository trigger in Bamboo.

```
PUT /projects/:id/services/bamboo
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | string | true | Bamboo root URL like https://bamboo.example.com |
| `build_key` | string | true | Bamboo build plan key like KEY |
| `username` | string | true | A user with API access, if applicable |
| `password` | string | true | Password of the user |

### Delete Atlassian Bamboo CI service

Delete Atlassian Bamboo CI service for a project.

```
DELETE /projects/:id/services/bamboo
```

### Get Atlassian Bamboo CI service settings

Get Atlassian Bamboo CI service settings for a project.

```
GET /projects/:id/services/bamboo
```

## Bugzilla

Bugzilla Issue Tracker

### Create/Edit Buildkite service

Set Bugzilla service for a project.

```
PUT /projects/:id/services/bugzilla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true |  New Issue url |
| `issues_url` | string | true | Issue url |
| `project_url` | string | true | Project url |
| `description` | string | false | Description |
| `title` | string | false | Title |

### Delete Bugzilla Service

Delete Bugzilla service for a project.

```
DELETE /projects/:id/services/bugzilla
```

### Get Bugzilla Service Settings

Get Bugzilla service settings for a project.

```
GET /projects/:id/services/bugzilla
```

## Buildkite

Continuous integration and deployments

### Create/Edit Buildkite service

Set Buildkite service for a project.

```
PUT /projects/:id/services/buildkite
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Buildkite project GitLab token |
| `project_url` | string | true | https://buildkite.com/example/project |
| `enable_ssl_verification` | boolean | false | Enable SSL verification |

### Delete Buildkite service

Delete Buildkite service for a project.

```
DELETE /projects/:id/services/buildkite
```

### Get Buildkite service settings

Get Buildkite service settings for a project.

```
GET /projects/:id/services/buildkite
```

## Campfire

Simple web-based real-time group chat

### Create/Edit Campfire service

Set Campfire service for a project.

```
PUT /projects/:id/services/campfire
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Campfire token |
| `subdomain` | string | false | Campfire subdomain |
| `room`  | string | false | Campfire room |

### Delete Campfire service

Delete Campfire service for a project.

```
DELETE /projects/:id/services/campfire
```

### Get Campfire service settings

Get Campfire service settings for a project.

```
GET /projects/:id/services/campfire
```

## Custom Issue Tracker

Custom issue tracker

### Create/Edit Custom Issue Tracker service

Set Custom Issue Tracker service for a project.

```
PUT /projects/:id/services/custom-issue-tracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true |  New Issue url
| `issues_url` | string | true | Issue url
| `project_url` | string | true | Project url
| `description` | string | false | Description
| `title` | string | false | Title

### Delete Custom Issue Tracker service

Delete Custom Issue Tracker service for a project.

```
DELETE /projects/:id/services/custom-issue-tracker
```

### Get Custom Issue Tracker service settings

Get Custom Issue Tracker service settings for a project.

```
GET /projects/:id/services/custom-issue-tracker
```

## Drone CI

Drone is a Continuous Integration platform built on Docker, written in Go

### Create/Edit Drone CI service

Set Drone CI service for a project.

```
PUT /projects/:id/services/drone-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Drone CI project specific token |
| `drone_url` | string | true | http://drone.example.com |
| `enable_ssl_verification` | boolean | false | Enable SSL verification |

### Delete Drone CI service

Delete Drone CI service for a project.

```
DELETE /projects/:id/services/drone-ci
```

### Get Drone CI service settings

Get Drone CI service settings for a project.

```
GET /projects/:id/services/drone-ci
```

## Emails on push

Email the commits and diff of each push to a list of recipients.

### Create/Edit Emails on push service

Set Emails on push service for a project.

```
PUT /projects/:id/services/emails-on-push
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | true | Emails separated by whitespace |
| `disable_diffs` | boolean | false | Disable code diffs |
| `send_from_committer_email` | boolean | false | Send from committer |

### Delete Emails on push service

Delete Emails on push service for a project.

```
DELETE /projects/:id/services/emails-on-push
```

### Get Emails on push service settings

Get Emails on push service settings for a project.

```
GET /projects/:id/services/emails-on-push
```

## External Wiki

Replaces the link to the internal wiki with a link to an external wiki.

### Create/Edit External Wiki service

Set External Wiki service for a project.

```
PUT /projects/:id/services/external-wiki
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | string | true | The URL of the external Wiki |

### Delete External Wiki service

Delete External Wiki service for a project.

```
DELETE /projects/:id/services/external-wiki
```

### Get External Wiki service settings

Get External Wiki service settings for a project.

```
GET /projects/:id/services/external-wiki
```

## Flowdock

Flowdock is a collaboration web app for technical teams.

### Create/Edit Flowdock service

Set Flowdock service for a project.

```
PUT /projects/:id/services/flowdock
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Flowdock Git source token |

### Delete Flowdock service

Delete Flowdock service for a project.

```
DELETE /projects/:id/services/flowdock
```

### Get Flowdock service settings

Get Flowdock service settings for a project.

```
GET /projects/:id/services/flowdock
```

## Gemnasium

Gemnasium monitors your project dependencies and alerts you about updates and security vulnerabilities.

### Create/Edit Gemnasium service

Set Gemnasium service for a project.

```
PUT /projects/:id/services/gemnasium
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | true | Your personal API KEY on gemnasium.com |
| `token`  | string | true | The project's slug on gemnasium.com |

### Delete Gemnasium service

Delete Gemnasium service for a project.

```
DELETE /projects/:id/services/gemnasium
```

### Get Gemnasium service settings

Get Gemnasium service settings for a project.

```
GET /projects/:id/services/gemnasium
```

## HipChat

Private group chat and IM

### Create/Edit HipChat service

Set HipChat service for a project.

```
PUT /projects/:id/services/hipchat
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Room token |
| `color` | string | false | The room color |
| `notify` | boolean | false | Enable notifications |
| `room` | string | false |Room name or ID |
| `api_version` | string | false | Leave blank for default (v2) |
| `server` | string | false | Leave blank for default. https://hipchat.example.com |

### Delete HipChat service

Delete HipChat service for a project.

```
DELETE /projects/:id/services/hipchat
```

### Get HipChat service settings

Get HipChat service settings for a project.

```
GET /projects/:id/services/hipchat
```

## Irker (IRC gateway)

Send IRC messages, on update, to a list of recipients through an Irker gateway.

### Create/Edit Irker (IRC gateway) service

Set Irker (IRC gateway) service for a project.

>  NOTE: Irker does NOT have built-in authentication, which makes it vulnerable to spamming IRC channels if it is hosted outside of a  firewall. Please make sure you run the daemon within a secured network  to prevent abuse. For more details, read: http://www.catb.org/~esr/irker/security.html.

```
PUT /projects/:id/services/irker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | true | Recipients/channels separated by whitespaces |
| `default_irc_uri` | string | false | irc://irc.network.net:6697/ |
| `server_host` | string | false | localhost |
| `server_port` | integer | false | 6659 |
| `colorize_messages` | boolean | false | Colorize messages |

### Delete Irker (IRC gateway) service

Delete Irker (IRC gateway) service for a project.

```
DELETE /projects/:id/services/irker
```

### Get Irker (IRC gateway) service settings

Get Irker (IRC gateway) service settings for a project.

```
GET /projects/:id/services/irker
```

## JIRA

JIRA issue tracker.

### Get JIRA service settings

Get JIRA service settings for a project.

```
GET /projects/:id/services/jira
```

### Create/Edit JIRA service

Set JIRA service for a project.

>**Notes:**
- Starting with GitLab 8.14, `api_url`, `issues_url`, `new_issue_url` and
  `project_url` are replaced by `project_key`, `url`.  If you are using an
  older version, [follow this documentation][old-jira-api].

```
PUT /projects/:id/services/jira
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `url`           | string | yes | The URL to the JIRA project which is being linked to this GitLab project, e.g., `https://jira.example.com`. |
| `project_key`   | string | yes | The short identifier for your JIRA project, all uppercase, e.g., `PROJ`. |
| `username`      | string | yes  | The username of the user created to be used with GitLab/JIRA. |
| `password`      | string | yes  | The password of the user created to be used with GitLab/JIRA. |
| `jira_issue_transition_id` | integer | no | The ID of a transition that moves issues to a closed state. You can find this number under the JIRA workflow administration (**Administration > Issues > Workflows**) by selecting **View** under **Operations** of the desired workflow of your project. The ID of each state can be found inside the parenthesis of each transition name under the **Transitions (id)** column ([see screenshot][trans]). By default, this ID is set to `2`. |

### Delete JIRA service

Remove all previously JIRA settings from a project.

```
DELETE /projects/:id/services/jira
```

## Kubernetes

Kubernetes / Openshift integration

CAUTION: **Warning:**
Kubernetes service integration has been deprecated in GitLab 10.3. API service endpoints will continue to work as long as the Kubernetes service is active, however if the service is inactive API endpoints will automatically return a `400 Bad Request`. Read [GitLab 10.3 release post](https://about.gitlab.com/2017/12/22/gitlab-10-3-released/#kubernetes-integration-service) for more information.

### Create/Edit Kubernetes service

Set Kubernetes service for a project.

```
PUT /projects/:id/services/kubernetes
```

Parameters:

- `namespace` (**required**) - The Kubernetes namespace to use
- `api_url` (**required**) - The URL to the Kubernetes cluster API, e.g., https://kubernetes.example.com
- `token` (**required**) - The service token to authenticate against the Kubernetes cluster with
- `ca_pem` (optional) - A custom certificate authority bundle to verify the Kubernetes cluster with (PEM format)

### Delete Kubernetes service

Delete Kubernetes service for a project.

```
DELETE /projects/:id/services/kubernetes
```

### Get Kubernetes service settings

Get Kubernetes service settings for a project.

```
GET /projects/:id/services/kubernetes
```

## Slack slash commands

Ability to receive slash commands from a Slack chat instance.

### Get Slack slash command service settings

Get Slack slash command service settings for a project.

```
GET /projects/:id/services/slack-slash-commands
```

Example response:

```json
{
  "id": 4,
  "title": "Slack slash commands",
  "created_at": "2017-06-27T05:51:39-07:00",
  "updated_at": "2017-06-27T05:51:39-07:00",
  "active": true,
  "push_events": true,
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "properties": {
    "token": "9koXpg98eAheJpvBs5tK"
  }
}
```

### Create/Edit Slack slash command service

Set Slack slash command for a project.

```
PUT /projects/:id/services/slack-slash-commands
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Slack token |


### Delete Slack slash command service

Delete Slack slash command service for a project.

```
DELETE /projects/:id/services/slack-slash-commands
```

## Mattermost slash commands

Ability to receive slash commands from a Mattermost chat instance.

### Get Mattermost slash command service settings

Get Mattermost slash command service settings for a project.

```
GET /projects/:id/services/mattermost-slash-commands
```

### Create/Edit Mattermost slash command service

Set Mattermost slash command for a project.

```
PUT /projects/:id/services/mattermost-slash-commands
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Mattermost token |
| `username` | string | no | The username to use to post the message |

### Delete Mattermost slash command service

Delete Mattermost slash command service for a project.

```
DELETE /projects/:id/services/mattermost-slash-commands
```

## Packagist

Update your project on Packagist, the main Composer repository, when commits or tags are pushed to GitLab.

### Create/Edit Packagist service

Set Packagist service for a project.

```
PUT /projects/:id/services/packagist
```

Parameters:

- `username` (**required**)
- `token` (**required**)
- `server` (optional)

### Delete Packagist service

Delete Packagist service for a project.

```
DELETE /projects/:id/services/packagist
```

### Get Packagist service settings

Get Packagist service settings for a project.

```
GET /projects/:id/services/packagist
```

## Pipeline-Emails

Get emails for GitLab CI pipelines.

### Create/Edit Pipeline-Emails service

Set Pipeline-Emails service for a project.

```
PUT /projects/:id/services/pipelines-email
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | yes | Comma-separated list of recipient email addresses |
| `add_pusher` | boolean | no | Add pusher to recipients list |
| `notify_only_broken_pipelines` | boolean | no | Notify only broken pipelines |

### Delete Pipeline-Emails service

Delete Pipeline-Emails service for a project.

```
DELETE /projects/:id/services/pipelines-email
```

### Get Pipeline-Emails service settings

Get Pipeline-Emails service settings for a project.

```
GET /projects/:id/services/pipelines-email
```

## PivotalTracker

Project Management Software (Source Commits Endpoint)

### Create/Edit PivotalTracker service

Set PivotalTracker service for a project.

```
PUT /projects/:id/services/pivotaltracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | The PivotalTracker token |
| `restrict_to_branch` | boolean | false | Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches. |

### Delete PivotalTracker service

Delete PivotalTracker service for a project.

```
DELETE /projects/:id/services/pivotaltracker
```

### Get PivotalTracker service settings

Get PivotalTracker service settings for a project.

```
GET /projects/:id/services/pivotaltracker
```

## Prometheus

Prometheus is a powerful time-series monitoring service.

### Create/Edit Prometheus service

Set Prometheus service for a project.

```
PUT /projects/:id/services/prometheus
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_url` | string | true | Prometheus API Base URL, like http://prometheus.example.com/ |

### Delete Prometheus service

Delete Prometheus service for a project.

```
DELETE /projects/:id/services/prometheus
```

### Get Prometheus service settings

Get Prometheus service settings for a project.

```
GET /projects/:id/services/prometheus
```

## Pushover

Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop.

### Create/Edit Pushover service

Set Pushover service for a project.

```
PUT /projects/:id/services/pushover
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | true | Your application key |
| `user_key` | string | true | Your user key |
| `priority` | string | true | The priority |
| `device` | string | false | Leave blank for all active devices |
| `sound` | string | false | The sound of the notification |

### Delete Pushover service

Delete Pushover service for a project.

```
DELETE /projects/:id/services/pushover
```

### Get Pushover service settings

Get Pushover service settings for a project.

```
GET /projects/:id/services/pushover
```

## Redmine

Redmine issue tracker

### Create/Edit Redmine service

Set Redmine service for a project.

```
PUT /projects/:id/services/redmine
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true | New Issue url |
| `project_url` | string | true | Project url |
| `issues_url` | string | true | Issue url |
| `description` | string | false | Description |

### Delete Redmine service

Delete Redmine service for a project.

```
DELETE /projects/:id/services/redmine
```

### Get Redmine service settings

Get Redmine service settings for a project.

```
GET /projects/:id/services/redmine
```

## Slack notifications

Receive event notifications in Slack

### Create/Edit Slack service

Set Slack service for a project.

```
PUT /projects/:id/services/slack
```

>**Note:** Specific event parameters (e.g. `push_events` flag and `push_channel`) were [introduced in v10.4][11435]

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | https://hooks.slack.com/services/... |
| `username` | string | false | username |
| `channel` | string | false | Default channel to use if others are not configured |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | Send notifications only for the default branch |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |
| `push_channel` | string | false | The name of the channel to receive push events notifications |
| `issue_channel` | string | false | The name of the channel to receive issues events notifications |
| `confidential_issue_channel` | string | false | The name of the channel to receive confidential issues events notifications |
| `merge_request_channel` | string | false | The name of the channel to receive merge request events notifications |
| `note_channel` | string | false | The name of the channel to receive note events notifications |
| `tag_push_channel` | string | false | The name of the channel to receive tag push events notifications |
| `pipeline_channel` | string | false | The name of the channel to receive pipeline events notifications |
| `wiki_page_channel` | string | false | The name of the channel to receive wiki page events notifications |

### Delete Slack service

Delete Slack service for a project.

```
DELETE /projects/:id/services/slack
```

### Get Slack service settings

Get Slack service settings for a project.

```
GET /projects/:id/services/slack
```

## Microsoft Teams

Group Chat Software

### Create/Edit Microsoft Teams service

Set Microsoft Teams service for a project.

```
PUT /projects/:id/services/microsoft-teams
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Microsoft Teams webhook. e.g. https://outlook.office.com/webhook/... |

### Delete Microsoft Teams service

Delete Microsoft Teams service for a project.

```
DELETE /projects/:id/services/microsoft-teams
```

### Get Microsoft Teams service settings

Get Microsoft Teams service settings for a project.

```
GET /projects/:id/services/microsoft-teams
```

## Mattermost notifications

Receive event notifications in Mattermost

### Create/Edit Mattermost notifications service

Set Mattermost service for a project.

```
PUT /projects/:id/services/mattermost
```

>**Note:** Specific event parameters (e.g. `push_events` flag and `push_channel`) were [introduced in v10.4][11435]

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Mattermost webhook. e.g. http://mattermost_host/hooks/... |
| `username` | string | false | username |
| `channel` | string | false | Default channel to use if others are not configured |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | Send notifications only for the default branch |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |
| `push_channel` | string | false | The name of the channel to receive push events notifications |
| `issue_channel` | string | false | The name of the channel to receive issues events notifications |
| `confidential_issue_channel` | string | false | The name of the channel to receive confidential issues events notifications |
| `merge_request_channel` | string | false | The name of the channel to receive merge request events notifications |
| `note_channel` | string | false | The name of the channel to receive note events notifications |
| `tag_push_channel` | string | false | The name of the channel to receive tag push events notifications |
| `pipeline_channel` | string | false | The name of the channel to receive pipeline events notifications |
| `wiki_page_channel` | string | false | The name of the channel to receive wiki page events notifications |

### Delete Mattermost notifications service

Delete Mattermost Notifications service for a project.

```
DELETE /projects/:id/services/mattermost
```

### Get Mattermost notifications service settings

Get Mattermost notifications service settings for a project.

```
GET /projects/:id/services/mattermost
```

## JetBrains TeamCity CI

A continuous integration and build server

### Create/Edit JetBrains TeamCity CI service

Set JetBrains TeamCity CI service for a project.

> The build configuration in Teamcity must use the build format number %build.vcs.number% you will also want to configure monitoring of all branches so merge requests build, that setting is in the vsc root advanced settings.

```
PUT /projects/:id/services/teamcity
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | string | true | TeamCity root URL like https://teamcity.example.com |
| `build_type` | string | true | Build configuration ID |
| `username` | string | true | A user with permissions to trigger a manual build |
| `password` | string | true | The password of the user |

### Delete JetBrains TeamCity CI service

Delete JetBrains TeamCity CI service for a project.

```
DELETE /projects/:id/services/teamcity
```

### Get JetBrains TeamCity CI service settings

Get JetBrains TeamCity CI service settings for a project.

```
GET /projects/:id/services/teamcity
```

## Jenkins CI

A continuous integration and build server

### Create/Edit Jenkins CI service

Set Jenkins CI service for a project.


```
PUT /projects/:id/services/jenkins
```

Parameters:

- `jenkins_url` (**required**) - Jenkins URL like http://jenkins.example.com
- `project_name` (**required**) - The URL-friendly project name. Example: my_project_name
- `username` (optional) - A user with access to the Jenkins server, if applicable
- `password` (optional) - The password of the user

### Delete Jenkins CI service

Delete Jenkins CI service for a project.

```
DELETE /projects/:id/services/jenkins
```

### Get Jenkins CI service settings

Get Jenkins CI service settings for a project.

```
GET /projects/:id/services/jenkins
```


## Jenkins CI (Deprecated) Service

A continuous integration and build server

### Create/Edit Jenkins CI (Deprecated) service

Set Jenkins CI (Deprecated) service for a project.

```
PUT /projects/:id/services/jenkins-deprecated
```

Parameters:

- `project_url` (**required**) - Jenkins project URL like http://jenkins.example.com/job/my-project/
- `multiproject_enabled` (optional) - Multi-project mode is configured in Jenkins Gitlab Hook plugin
- `pass_unstable` (optional) - Unstable builds will be treated as passing

### Delete Jenkins CI (Deprecated) service

Delete Jenkins CI (Deprecated) service for a project.

```
DELETE /projects/:id/services/jenkins-deprecated
```

### Get Jenkins CI (Deprecated) service settings

Get Jenkins CI (Deprecated) service settings for a project.

```
GET /projects/:id/services/jenkins-deprecated
```

[jira-doc]: ../user/project/integrations/jira.md
[old-jira-api]: https://gitlab.com/gitlab-org/gitlab-ce/blob/8-13-stable/doc/api/services.md#jira


## MockCI

Mock an external CI. See [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service) for an example of a companion mock service.

This service is only available when your environment is set to development.

### Create/Edit MockCI service

Set MockCI service for a project.

```
PUT /projects/:id/services/mock-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | string | true | http://localhost:4004 |

### Delete MockCI service

Delete MockCI service for a project.

```
DELETE /projects/:id/services/mock-ci
```

### Get MockCI service settings

Get MockCI service settings for a project.

```
GET /projects/:id/services/mock-ci
```

[11435]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11435
