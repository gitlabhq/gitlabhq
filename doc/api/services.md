---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Services API **(FREE)**

NOTE:
This API requires an access token with the [Maintainer or Owner role](../user/permissions.md).

## List all active services

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21330) in GitLab 12.7.

Get a list of all active project services.

```plaintext
GET /projects/:id/services
```

Example response:

```json
[
  {
    "id": 75,
    "title": "Jenkins CI",
    "slug": "jenkins",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true
  },
  {
    "id": 76,
    "title": "Alerts endpoint",
    "slug": "alerts",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": true,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true
  }
]
```

## Asana

Add commit messages as comments to Asana tasks.

See also the [Asana service documentation](../user/project/integrations/asana.md).

### Create/Edit Asana service

Set Asana service for a project.

```plaintext
PUT /projects/:id/services/asana
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | true | User API token. User must have access to task. All comments are attributed to this user. |
| `restrict_to_branch` | string | false | Comma-separated list of branches to be are automatically inspected. Leave blank to include all branches. |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Asana service

Delete Asana service for a project.

```plaintext
DELETE /projects/:id/services/asana
```

### Get Asana service settings

Get Asana service settings for a project.

```plaintext
GET /projects/:id/services/asana
```

## Assembla

Project Management Software (Source Commits Endpoint)

### Create/Edit Assembla service

Set Assembla service for a project.

```plaintext
PUT /projects/:id/services/assembla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | The authentication token
| `subdomain` | string | false | The subdomain setting |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Assembla service

Delete Assembla service for a project.

```plaintext
DELETE /projects/:id/services/assembla
```

### Get Assembla service settings

Get Assembla service settings for a project.

```plaintext
GET /projects/:id/services/assembla
```

## Atlassian Bamboo CI

A continuous integration and build server

### Create/Edit Atlassian Bamboo CI service

Set Atlassian Bamboo CI service for a project.

> You must set up automatic revision labeling and a repository trigger in Bamboo.

```plaintext
PUT /projects/:id/services/bamboo
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | string | true | Bamboo root URL. For example, `https://bamboo.example.com`. |
| `build_key` | string | true | Bamboo build plan key like KEY |
| `username` | string | true | A user with API access, if applicable |
| `password` | string | true | Password of the user |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Atlassian Bamboo CI service

Delete Atlassian Bamboo CI service for a project.

```plaintext
DELETE /projects/:id/services/bamboo
```

### Get Atlassian Bamboo CI service settings

Get Atlassian Bamboo CI service settings for a project.

```plaintext
GET /projects/:id/services/bamboo
```

## Bugzilla

Bugzilla Issue Tracker

### Create/Edit Bugzilla service

Set Bugzilla service for a project.

```plaintext
PUT /projects/:id/services/bugzilla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true |  New Issue URL |
| `issues_url` | string | true | Issue URL |
| `project_url` | string | true | Project URL |
| `description` | string | false | Description |
| `title` | string | false | Title |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Bugzilla Service

Delete Bugzilla service for a project.

```plaintext
DELETE /projects/:id/services/bugzilla
```

### Get Bugzilla Service Settings

Get Bugzilla service settings for a project.

```plaintext
GET /projects/:id/services/bugzilla
```

## Buildkite

Continuous integration and deployments

### Create/Edit Buildkite service

Set Buildkite service for a project.

```plaintext
PUT /projects/:id/services/buildkite
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Buildkite project GitLab token |
| `project_url` | string | true | Pipeline URL. For example, `https://buildkite.com/example/pipeline` |
| `enable_ssl_verification` | boolean | false | DEPRECATED: This parameter has no effect since SSL verification is always enabled |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Buildkite service

Delete Buildkite service for a project.

```plaintext
DELETE /projects/:id/services/buildkite
```

### Get Buildkite service settings

Get Buildkite service settings for a project.

```plaintext
GET /projects/:id/services/buildkite
```

## Campfire

Send notifications about push events to Campfire chat rooms.
Note that [new users can no longer sign up for Campfire](https://basecamp.com/retired/campfire).

### Create/Edit Campfire service

Set Campfire service for a project.

```plaintext
PUT /projects/:id/services/campfire
```

Parameters:

| Parameter     | Type    | Required | Description                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | string  | true     | Campfire API token. To find it, log into Campfire and select **My info**.                   |
| `subdomain`   | string  | false    | Campfire subdomain. Text between `https://` and `.campfirenow.com` when you're logged in. |
| `room`        | string  | false    | Campfire room. The last part of the URL when you're in a room.                              |
| `push_events` | boolean | false    | Enable notifications for push events.                                                       |

### Delete Campfire service

Delete Campfire service for a project.

```plaintext
DELETE /projects/:id/services/campfire
```

### Get Campfire service settings

Get Campfire service settings for a project.

```plaintext
GET /projects/:id/services/campfire
```

## Unify Circuit

Unify Circuit RTC and collaboration tool.

### Create/Edit Unify Circuit service

Set Unify Circuit service for a project.

```plaintext
PUT /projects/:id/services/unify-circuit
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Unify Circuit webhook. For example, `https://circuit.com/rest/v2/webhooks/incoming/...`. |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected". The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Delete Unify Circuit service

Delete Unify Circuit service for a project.

```plaintext
DELETE /projects/:id/services/unify-circuit
```

### Get Unify Circuit service settings

Get Unify Circuit service settings for a project.

```plaintext
GET /projects/:id/services/unify-circuit
```

## Webex Teams

Webex Teams collaboration tool.

### Create/Edit Webex Teams service

Set Webex Teams service for a project.

```plaintext
PUT /projects/:id/services/webex-teams
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Webex Teams webhook. For example, `https://api.ciscospark.com/v1/webhooks/incoming/...`. |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected". The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Delete Webex Teams service

Delete Webex Teams service for a project.

```plaintext
DELETE /projects/:id/services/webex-teams
```

### Get Webex Teams service settings

Get Webex Teams service settings for a project.

```plaintext
GET /projects/:id/services/webex-teams
```

## Custom Issue Tracker

Custom issue tracker

### Create/Edit Custom Issue Tracker service

Set Custom Issue Tracker service for a project.

```plaintext
PUT /projects/:id/services/custom-issue-tracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true |  New Issue URL |
| `issues_url` | string | true | Issue URL |
| `project_url` | string | true | Project URL |
| `description` | string | false | Description |
| `title` | string | false | Title |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Custom Issue Tracker service

Delete Custom Issue Tracker service for a project.

```plaintext
DELETE /projects/:id/services/custom-issue-tracker
```

### Get Custom Issue Tracker service settings

Get Custom Issue Tracker service settings for a project.

```plaintext
GET /projects/:id/services/custom-issue-tracker
```

## Drone CI

Drone is a Continuous Integration platform built on Docker, written in Go

### Create/Edit Drone CI service

Set Drone CI service for a project.

```plaintext
PUT /projects/:id/services/drone-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Drone CI project specific token |
| `drone_url` | string | true | `http://drone.example.com` |
| `enable_ssl_verification` | boolean | false | Enable SSL verification |
| `push_events` | boolean | false | Enable notifications for push events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |

### Delete Drone CI service

Delete Drone CI service for a project.

```plaintext
DELETE /projects/:id/services/drone-ci
```

### Get Drone CI service settings

Get Drone CI service settings for a project.

```plaintext
GET /projects/:id/services/drone-ci
```

## Emails on push

Email the commits and diff of each push to a list of recipients.

### Create/Edit Emails on push service

Set Emails on push service for a project.

```plaintext
PUT /projects/:id/services/emails-on-push
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | true | Emails separated by whitespace |
| `disable_diffs` | boolean | false | Disable code diffs |
| `send_from_committer_email` | boolean | false | Send from committer |
| `push_events` | boolean | false | Enable notifications for push events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected". Notifications are always fired for tag pushes. The default value is "all" |

### Delete Emails on push service

Delete Emails on push service for a project.

```plaintext
DELETE /projects/:id/services/emails-on-push
```

### Get Emails on push service settings

Get Emails on push service settings for a project.

```plaintext
GET /projects/:id/services/emails-on-push
```

## Confluence service

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220934) in GitLab 13.2.

Replaces the link to the internal wiki with a link to a Confluence Cloud Workspace.

### Create/Edit Confluence service

Set Confluence service for a project.

```plaintext
PUT /projects/:id/services/confluence
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | string | true | The URL of the Confluence Cloud Workspace hosted on atlassian.net.  |

### Delete Confluence service

Delete Confluence service for a project.

```plaintext
DELETE /projects/:id/services/confluence
```

### Get Confluence service settings

Get Confluence service settings for a project.

```plaintext
GET /projects/:id/services/confluence
```

## External wiki

Replaces the link to the internal wiki with a link to an external wiki.

### Create/Edit External wiki service

Set External wiki service for a project.

```plaintext
PUT /projects/:id/services/external-wiki
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | string | true | The URL of the external wiki |

### Delete External wiki service

Delete External wiki service for a project.

```plaintext
DELETE /projects/:id/services/external-wiki
```

### Get External wiki service settings

Get External wiki service settings for a project.

```plaintext
GET /projects/:id/services/external-wiki
```

## Flowdock

Flowdock is a ChatOps application for collaboration in software engineering
companies. You can send notifications from GitLab events to Flowdock flows.
For integration instructions, see the [Flowdock documentation](https://www.flowdock.com/help/gitlab).

### Create/Edit Flowdock service

Set Flowdock service for a project.

```plaintext
PUT /projects/:id/services/flowdock
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Flowdock Git source token |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Flowdock service

Delete Flowdock service for a project.

```plaintext
DELETE /projects/:id/services/flowdock
```

### Get Flowdock service settings

Get Flowdock service settings for a project.

```plaintext
GET /projects/:id/services/flowdock
```

## GitHub **(PREMIUM)**

Code collaboration software.

### Create/Edit GitHub service

Set GitHub service for a project.

```plaintext
PUT /projects/:id/services/github
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | GitHub API token with `repo:status` OAuth scope |
| `repository_url` | string | true | GitHub repository URL |
| `static_context` | boolean | false | Append instance name instead of branch to [status check name](../user/project/integrations/github.md#static--dynamic-status-check-names) |

### Delete GitHub service

Delete GitHub service for a project.

```plaintext
DELETE /projects/:id/services/github
```

### Get GitHub service settings

Get GitHub service settings for a project.

```plaintext
GET /projects/:id/services/github
```

## Hangouts Chat

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/20290) in GitLab 11.2.

Google Workspace team collaboration tool.

### Create/Edit Hangouts Chat service

Set Hangouts Chat service for a project.

```plaintext
PUT /projects/:id/services/hangouts-chat
```

NOTE:
Specific event parameters (for example, `push_events` flag) were [introduced in v10.4](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/11435)

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Hangouts Chat webhook. For example, `https://chat.googleapis.com/v1/spaces...`. |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected". The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Delete Hangouts Chat service

Delete Hangouts Chat service for a project.

```plaintext
DELETE /projects/:id/services/hangouts-chat
```

### Get Hangouts Chat service settings

Get Hangouts Chat service settings for a project.

```plaintext
GET /projects/:id/services/hangouts-chat
```

## Irker (IRC gateway)

Send IRC messages, on update, to a list of recipients through an Irker gateway.

### Create/Edit Irker (IRC gateway) service

Set Irker (IRC gateway) service for a project.

NOTE:
Irker does NOT have built-in authentication, which makes it vulnerable to spamming IRC channels if it is hosted outside of a firewall. Please make sure you run the daemon within a secured network to prevent abuse. For more details, read [Security analysis of `irker`](http://www.catb.org/~esr/irker/security.html).

```plaintext
PUT /projects/:id/services/irker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | true | Recipients/channels separated by whitespaces |
| `default_irc_uri` | string | false | `irc://irc.network.net:6697/` |
| `server_host` | string | false | localhost |
| `server_port` | integer | false | 6659 |
| `colorize_messages` | boolean | false | Colorize messages |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Irker (IRC gateway) service

Delete Irker (IRC gateway) service for a project.

```plaintext
DELETE /projects/:id/services/irker
```

### Get Irker (IRC gateway) service settings

Get Irker (IRC gateway) service settings for a project.

```plaintext
GET /projects/:id/services/irker
```

## Jira

Jira issue tracker.

### Get Jira service settings

Get Jira service settings for a project.

```plaintext
GET /projects/:id/services/jira
```

### Create/Edit Jira service

Set Jira service for a project.

> Starting with GitLab 8.14, `api_url`, `issues_url`, `new_issue_url` and
> `project_url` are replaced by `url`. If you are using an
> older version, [follow this documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/8-13-stable-ee/doc/api/services.md#jira).

```plaintext
PUT /projects/:id/services/jira
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `url`           | string | yes | The URL to the Jira project which is being linked to this GitLab project. For example, `https://jira.example.com`. |
| `api_url`   | string | no | The base URL to the Jira instance API. Web URL value is used if not set. For example, `https://jira-api.example.com`. |
| `username`      | string | yes  | The username of the user created to be used with GitLab/Jira. |
| `password`      | string | yes  | The password of the user created to be used with GitLab/Jira. |
| `active`        | boolean | no  | Activates or deactivates the service. Defaults to false (deactivated). |
| `jira_issue_transition_automatic` | boolean | no | Enable [automatic issue transitions](../integration/jira/issues.md#automatic-issue-transitions). Takes precedence over `jira_issue_transition_id` if enabled. Defaults to `false` |
| `jira_issue_transition_id` | string | no | The ID of one or more transitions for [custom issue transitions](../integration/jira/issues.md#custom-issue-transitions). Ignored if `jira_issue_transition_automatic` is enabled. Defaults to a blank string, which disables custom transitions. |
| `commit_events` | boolean | false | Enable notifications for commit events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `comment_on_event_enabled` | boolean | false | Enable comments inside Jira issues on each GitLab event (commit / merge request) |

### Delete Jira service

Remove all previously Jira settings from a project.

```plaintext
DELETE /projects/:id/services/jira
```

## Slack slash commands

Ability to receive slash commands from a Slack chat instance.

### Get Slack slash command service settings

Get Slack slash command service settings for a project.

```plaintext
GET /projects/:id/services/slack-slash-commands
```

Example response:

```json
{
  "id": 4,
  "title": "Slack slash commands",
  "slug": "slack-slash-commands",
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
  "comment_on_event_enabled": false,
  "properties": {
    "token": "<your_access_token>"
  }
}
```

### Create/Edit Slack slash command service

Set Slack slash command for a project.

```plaintext
PUT /projects/:id/services/slack-slash-commands
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Slack token |

### Delete Slack slash command service

Delete Slack slash command service for a project.

```plaintext
DELETE /projects/:id/services/slack-slash-commands
```

## Mattermost slash commands

Ability to receive slash commands from a Mattermost chat instance.

### Get Mattermost slash command service settings

Get Mattermost slash command service settings for a project.

```plaintext
GET /projects/:id/services/mattermost-slash-commands
```

### Create/Edit Mattermost slash command service

Set Mattermost slash command for a project.

```plaintext
PUT /projects/:id/services/mattermost-slash-commands
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Mattermost token |
| `username` | string | no | The username to use to post the message |

### Delete Mattermost slash command service

Delete Mattermost slash command service for a project.

```plaintext
DELETE /projects/:id/services/mattermost-slash-commands
```

## Packagist

Update your project on Packagist (the main Composer repository) when commits or tags are pushed to GitLab.

### Create/Edit Packagist service

Set Packagist service for a project.

```plaintext
PUT /projects/:id/services/packagist
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `username` | string | yes | The username of a Packagist account |
| `token` | string | yes | API token to the Packagist server |
| `server` | boolean | no | URL of the Packagist server. Leave blank for default: <https://packagist.org> |
| `push_events` | boolean | false | Enable notifications for push events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |

### Delete Packagist service

Delete Packagist service for a project.

```plaintext
DELETE /projects/:id/services/packagist
```

### Get Packagist service settings

Get Packagist service settings for a project.

```plaintext
GET /projects/:id/services/packagist
```

## Pipeline-Emails

Get emails for GitLab CI/CD pipelines.

### Create/Edit Pipeline-Emails service

Set Pipeline-Emails service for a project.

```plaintext
PUT /projects/:id/services/pipelines-email
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | yes | Comma-separated list of recipient email addresses |
| `add_pusher` | boolean | no | Add pusher to recipients list |
| `notify_only_broken_pipelines` | boolean | no | Notify only broken pipelines |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected. The default value is "default" |
| `notify_only_default_branch` | boolean | no | Send notifications only for the default branch ([introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/28271)) |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |

### Delete Pipeline-Emails service

Delete Pipeline-Emails service for a project.

```plaintext
DELETE /projects/:id/services/pipelines-email
```

### Get Pipeline-Emails service settings

Get Pipeline-Emails service settings for a project.

```plaintext
GET /projects/:id/services/pipelines-email
```

## Pivotal Tracker

Add commit messages as comments to Pivotal Tracker stories.

See also the [Pivotal Tracker service documentation](../user/project/integrations/pivotal_tracker.md).

### Create/Edit Pivotal Tracker service

Set Pivotal Tracker service for a project.

```plaintext
PUT /projects/:id/services/pivotaltracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | The Pivotal Tracker token |
| `restrict_to_branch` | boolean | false | Comma-separated list of branches to automatically inspect. Leave blank to include all branches. |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Pivotal Tracker service

Delete Pivotal Tracker service for a project.

```plaintext
DELETE /projects/:id/services/pivotaltracker
```

### Get Pivotal Tracker service settings

Get Pivotal Tracker service settings for a project.

```plaintext
GET /projects/:id/services/pivotaltracker
```

## Prometheus

Prometheus is a powerful time-series monitoring service.

### Create/Edit Prometheus service

Set Prometheus service for a project.

```plaintext
PUT /projects/:id/services/prometheus
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_url` | string | true | Prometheus API Base URL. For example, `http://prometheus.example.com/`. |
| `google_iap_audience_client_id` | string | false | Client ID of the IAP secured resource (looks like IAP_CLIENT_ID.apps.googleusercontent.com) |
| `google_iap_service_account_json` | string | false | `credentials.json` file for your service account, like { "type": "service_account", "project_id": ... } |

### Delete Prometheus service

Delete Prometheus service for a project.

```plaintext
DELETE /projects/:id/services/prometheus
```

### Get Prometheus service settings

Get Prometheus service settings for a project.

```plaintext
GET /projects/:id/services/prometheus
```

## Pushover

Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop.

### Create/Edit Pushover service

Set Pushover service for a project.

```plaintext
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
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Pushover service

Delete Pushover service for a project.

```plaintext
DELETE /projects/:id/services/pushover
```

### Get Pushover service settings

Get Pushover service settings for a project.

```plaintext
GET /projects/:id/services/pushover
```

## Redmine

Redmine issue tracker

### Create/Edit Redmine service

Set Redmine service for a project.

```plaintext
PUT /projects/:id/services/redmine
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true | New Issue URL |
| `project_url` | string | true | Project URL |
| `issues_url` | string | true | Issue URL |
| `description` | string | false | Description |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete Redmine service

Delete Redmine service for a project.

```plaintext
DELETE /projects/:id/services/redmine
```

### Get Redmine service settings

Get Redmine service settings for a project.

```plaintext
GET /projects/:id/services/redmine
```

## Slack notifications

Receive event notifications in Slack

### Create/Edit Slack service

Set Slack service for a project.

```plaintext
PUT /projects/:id/services/slack
```

NOTE:
Specific event parameters (for example, `push_events` flag and `push_channel`) were [introduced in v10.4](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/11435)

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | `https://hooks.slack.com/services/...` |
| `username` | string | false | username |
| `channel` | string | false | Default channel to use if others are not configured |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected". The default value is "default" |
| `commit_events` | boolean | false | Enable notifications for commit events |
| `confidential_issue_channel` | string | false | The name of the channel to receive confidential issues events notifications |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `confidential_note_channel` | string | false | The name of the channel to receive confidential note events notifications |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `deployment_channel` | string | false | The name of the channel to receive deployment events notifications |
| `deployment_events` | boolean | false | Enable notifications for deployment events |
| `issue_channel` | string | false | The name of the channel to receive issues events notifications |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `job_events` | boolean | false | Enable notifications for job events |
| `merge_request_channel` | string | false | The name of the channel to receive merge request events notifications |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `note_channel` | string | false | The name of the channel to receive note events notifications |
| `note_events` | boolean | false | Enable notifications for note events |
| `pipeline_channel` | string | false | The name of the channel to receive pipeline events notifications |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `push_channel` | string | false | The name of the channel to receive push events notifications |
| `push_events` | boolean | false | Enable notifications for push events |
| `tag_push_channel` | string | false | The name of the channel to receive tag push events notifications |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `wiki_page_channel` | string | false | The name of the channel to receive wiki page events notifications |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Delete Slack service

Delete Slack service for a project.

```plaintext
DELETE /projects/:id/services/slack
```

### Get Slack service settings

Get Slack service settings for a project.

```plaintext
GET /projects/:id/services/slack
```

## Microsoft Teams

Group Chat Software

### Create/Edit Microsoft Teams service

Set Microsoft Teams service for a project.

```plaintext
PUT /projects/:id/services/microsoft-teams
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Microsoft Teams webhook. For example, `https://outlook.office.com/webhook/...` |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected". The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Delete Microsoft Teams service

Delete Microsoft Teams service for a project.

```plaintext
DELETE /projects/:id/services/microsoft-teams
```

### Get Microsoft Teams service settings

Get Microsoft Teams service settings for a project.

```plaintext
GET /projects/:id/services/microsoft-teams
```

## Mattermost notifications

Receive event notifications in Mattermost

### Create/Edit Mattermost notifications service

Set Mattermost service for a project.

```plaintext
PUT /projects/:id/services/mattermost
```

NOTE:
Specific event parameters (for example, `push_events` flag and `push_channel`) were [introduced in v10.4](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/11435)

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Mattermost webhook. For example, `http://mattermost_host/hooks/...` |
| `username` | string | false | username |
| `channel` | string | false | Default channel to use if others are not configured |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are "all", "default", "protected", and "default_and_protected". The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |
| `push_channel` | string | false | The name of the channel to receive push events notifications |
| `issue_channel` | string | false | The name of the channel to receive issues events notifications |
| `confidential_issue_channel` | string | false | The name of the channel to receive confidential issues events notifications |
| `merge_request_channel` | string | false | The name of the channel to receive merge request events notifications |
| `note_channel` | string | false | The name of the channel to receive note events notifications |
| `confidential_note_channel` | string | false | The name of the channel to receive confidential note events notifications |
| `tag_push_channel` | string | false | The name of the channel to receive tag push events notifications |
| `pipeline_channel` | string | false | The name of the channel to receive pipeline events notifications |
| `wiki_page_channel` | string | false | The name of the channel to receive wiki page events notifications |

### Delete Mattermost notifications service

Delete Mattermost Notifications service for a project.

```plaintext
DELETE /projects/:id/services/mattermost
```

### Get Mattermost notifications service settings

Get Mattermost notifications service settings for a project.

```plaintext
GET /projects/:id/services/mattermost
```

## JetBrains TeamCity CI

A continuous integration and build server

### Create/Edit JetBrains TeamCity CI service

Set JetBrains TeamCity CI service for a project.

> The build configuration in TeamCity must use the build format number `%build.vcs.number%`. Configure monitoring of all branches so merge requests build. That setting is in the VSC root advanced settings.

```plaintext
PUT /projects/:id/services/teamcity
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | string | true | TeamCity root URL. For example, `https://teamcity.example.com` |
| `build_type` | string | true | Build configuration ID |
| `username` | string | true | A user with permissions to trigger a manual build |
| `password` | string | true | The password of the user |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete JetBrains TeamCity CI service

Delete JetBrains TeamCity CI service for a project.

```plaintext
DELETE /projects/:id/services/teamcity
```

### Get JetBrains TeamCity CI service settings

Get JetBrains TeamCity CI service settings for a project.

```plaintext
GET /projects/:id/services/teamcity
```

## Jenkins CI

A continuous integration and build server

### Create/Edit Jenkins CI service

Set Jenkins CI service for a project.

```plaintext
PUT /projects/:id/services/jenkins
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `jenkins_url` | string | true | Jenkins URL like `http://jenkins.example.com`. |
| `project_name` | string | true | The URL-friendly project name. Example: `my_project_name`. |
| `username` | string | false | Username for authentication with the Jenkins server, if authentication is required by the server. |
| `password` | string | false | Password for authentication with the Jenkins server, if authentication is required by the server. |
| `push_events` | boolean | false | Enable notifications for push events. |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events. |
| `tag_push_events` | boolean | false | Enable notifications for tag push events. |

### Delete Jenkins CI service

Delete Jenkins CI service for a project.

```plaintext
DELETE /projects/:id/services/jenkins
```

### Get Jenkins CI service settings

Get Jenkins CI service settings for a project.

```plaintext
GET /projects/:id/services/jenkins
```

## Jenkins CI (Deprecated) Service

A continuous integration and build server

NOTE:
This service was [removed in v13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/1600)

### Create/Edit Jenkins CI (Deprecated) service

Set Jenkins CI (Deprecated) service for a project.

```plaintext
PUT /projects/:id/services/jenkins-deprecated
```

Parameters:

- `project_url` (**required**) - Jenkins project URL like `http://jenkins.example.com/job/my-project/`
- `multiproject_enabled` (optional) - Multi-project mode is configured in Jenkins GitLab Hook plugin
- `pass_unstable` (optional) - Unstable builds are treated as passing

### Delete Jenkins CI (Deprecated) service

Delete Jenkins CI (Deprecated) service for a project.

```plaintext
DELETE /projects/:id/services/jenkins-deprecated
```

### Get Jenkins CI (Deprecated) service settings

Get Jenkins CI (Deprecated) service settings for a project.

```plaintext
GET /projects/:id/services/jenkins-deprecated
```

## MockCI

Mock an external CI. See [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service) for an example of a companion mock service.

This service is only available when your environment is set to development.

### Create/Edit MockCI service

Set MockCI service for a project.

```plaintext
PUT /projects/:id/services/mock-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | string | true | `http://localhost:4004` |

### Delete MockCI service

Delete MockCI service for a project.

```plaintext
DELETE /projects/:id/services/mock-ci
```

### Get MockCI service settings

Get MockCI service settings for a project.

```plaintext
GET /projects/:id/services/mock-ci
```

## YouTrack

YouTrack issue tracker

### Create/Edit YouTrack service

Set YouTrack service for a project.

```plaintext
PUT /projects/:id/services/youtrack
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `issues_url` | string | true | Issue URL |
| `project_url` | string | true | Project URL |
| `description` | string | false | Description |
| `push_events` | boolean | false | Enable notifications for push events |

### Delete YouTrack Service

Delete YouTrack service for a project.

```plaintext
DELETE /projects/:id/services/youtrack
```

### Get YouTrack Service Settings

Get YouTrack service settings for a project.

```plaintext
GET /projects/:id/services/youtrack
```
