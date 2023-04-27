---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Integrations API **(FREE)**

This API enables you to work with external services that integrate with GitLab.

NOTE:
In GitLab 14.4, the `services` endpoint was [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/334500) to `integrations`.
Calls to the Integrations API can be made to both `/projects/:id/services` and `/projects/:id/integrations`.
The examples in this document refer to the endpoint at `/projects/:id/integrations`.

This API requires an access token with the Maintainer or Owner role.

## List all active integrations

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21330) in GitLab 12.7.

Get a list of all active project integrations.

```plaintext
GET /projects/:id/integrations
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

## Apple App Store

Use GitLab to build and release an app in the Apple App Store.

See also the [Apple App Store integration documentation](../user/project/integrations/apple_app_store.md).

### Create/Edit Apple App Store integration

Set Apple App Store integration for a project.

```plaintext
PUT /projects/:id/integrations/apple_app_store
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `app_store_issuer_id` | string | true | The Apple App Store Connect Issuer ID. |
| `app_store_key_id` | string | true | The Apple App Store Connect Key ID. |
| `app_store_private_key` | string | true | The Apple App Store Connect Private Key. |

### Disable Apple App Store integration

Disable the Apple App Store integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/apple_app_store
```

### Get Apple App Store integration settings

Get Apple App Store integration settings for a project.

```plaintext
GET /projects/:id/integrations/apple_app_store
```

## Asana

Add commit messages as comments to Asana tasks.

See also the [Asana integration documentation](../user/project/integrations/asana.md).

### Create/Edit Asana integration

Set Asana integration for a project.

```plaintext
PUT /projects/:id/integrations/asana
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | true | User API token. User must have access to task. All comments are attributed to this user. |
| `restrict_to_branch` | string | false | Comma-separated list of branches to be are automatically inspected. Leave blank to include all branches. |

### Disable Asana integration

Disable the Asana integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/asana
```

### Get Asana integration settings

Get Asana integration settings for a project.

```plaintext
GET /projects/:id/integrations/asana
```

## Assembla

Project Management Software (Source Commits Endpoint)

### Create/Edit Assembla integration

Set Assembla integration for a project.

```plaintext
PUT /projects/:id/integrations/assembla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | The authentication token
| `subdomain` | string | false | The subdomain setting |

### Disable Assembla integration

Disable the Assembla integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/assembla
```

### Get Assembla integration settings

Get Assembla integration settings for a project.

```plaintext
GET /projects/:id/integrations/assembla
```

## Atlassian Bamboo CI

A continuous integration and build server

### Create/Edit Atlassian Bamboo CI integration

Set Atlassian Bamboo CI integration for a project.

> You must set up automatic revision labeling and a repository trigger in Bamboo.

```plaintext
PUT /projects/:id/integrations/bamboo
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | string | true | Bamboo root URL. For example, `https://bamboo.example.com`. |
| `enable_ssl_verification` | boolean | false | Enable SSL verification. Defaults to true (enabled). |
| `build_key` | string | true | Bamboo build plan key like KEY |
| `username` | string | true | A user with API access, if applicable |
| `password` | string | true | Password of the user |

### Disable Atlassian Bamboo CI integration

Disable the Atlassian Bamboo CI integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/bamboo
```

### Get Atlassian Bamboo CI integration settings

Get Atlassian Bamboo CI integration settings for a project.

```plaintext
GET /projects/:id/integrations/bamboo
```

## Bugzilla

Bugzilla Issue Tracker

### Create/Edit Bugzilla integration

Set Bugzilla integration for a project.

```plaintext
PUT /projects/:id/integrations/bugzilla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true |  New Issue URL |
| `issues_url` | string | true | Issue URL |
| `project_url` | string | true | Project URL |

### Disable Bugzilla integration

Disable the Bugzilla integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/bugzilla
```

### Get Bugzilla integration settings

Get Bugzilla integration settings for a project.

```plaintext
GET /projects/:id/integrations/bugzilla
```

## Buildkite

Continuous integration and deployments

### Create/Edit Buildkite integration

Set Buildkite integration for a project.

```plaintext
PUT /projects/:id/integrations/buildkite
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Buildkite project GitLab token |
| `project_url` | string | true | Pipeline URL. For example, `https://buildkite.com/example/pipeline` |
| `enable_ssl_verification` | boolean | false | DEPRECATED: This parameter has no effect since SSL verification is always enabled |
| `push_events` | boolean | false | Enable notifications for push events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |

### Disable Buildkite integration

Disable the Buildkite integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/buildkite
```

### Get Buildkite integration settings

Get Buildkite integration settings for a project.

```plaintext
GET /projects/:id/integrations/buildkite
```

## Campfire

Send notifications about push events to Campfire chat rooms.
[New users can no longer sign up for Campfire](https://basecamp.com/handbook/05-product-histories#campfire).

### Create/Edit Campfire integration

Set Campfire integration for a project.

```plaintext
PUT /projects/:id/integrations/campfire
```

Parameters:

| Parameter     | Type    | Required | Description                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | string  | true     | Campfire API token. To find it, sign in to Campfire and select **My info**.                   |
| `subdomain`   | string  | false    | Campfire subdomain. Text between `https://` and `.campfirenow.com` when you're logged in. |
| `room`        | string  | false    | Campfire room. The last part of the URL when you're in a room.                              |

### Disable Campfire integration

Disable the Campfire integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/campfire
```

### Get Campfire integration settings

Get Campfire integration settings for a project.

```plaintext
GET /projects/:id/integrations/campfire
```

## Datadog

Datadog system monitoring.

### Create/Edit Datadog integration

Set Datadog integration for a project.

```plaintext
PUT /projects/:id/integrations/datadog
```

Parameters:

| Parameter              | Type    | Required | Description                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | string  | true     | API key used for authentication with Datadog.                                                                                                                                          |
| `api_url`              | string  | false    | (Advanced) The full URL for your Datadog site                                                                                                                                          |
| `datadog_env`          | string  | false    | For self-managed deployments, set the env% tag for all the data sent to Datadog.                                                                                                       |
| `datadog_service`      | string  | false    | Tag all data from this GitLab instance in Datadog. Useful when managing several self-managed deployments                                                                               |
| `datadog_site`         | string  | false    | The Datadog site to send data to. To send data to the EU site, use `datadoghq.eu`                                                                                                      |
| `datadog_tags`         | string  | false    | Custom tags in Datadog. Specify one tag per line in the format: `key:value\nkey2:value2` ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/79665) in GitLab 14.8.)   |
| `archive_trace_events` | boolean | false    | When enabled, job logs are collected by Datadog and displayed along with pipeline execution traces ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346339) in GitLab 15.3) |

### Disable Datadog integration

Disable the Datadog integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/datadog
```

### Get Datadog integration settings

Get Datadog integration settings for a project.

```plaintext
GET /projects/:id/integrations/datadog
```

## Unify Circuit

Unify Circuit RTC and collaboration tool.

### Create/Edit Unify Circuit integration

Set Unify Circuit integration for a project.

```plaintext
PUT /projects/:id/integrations/unify-circuit
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Unify Circuit webhook. For example, `https://circuit.com/rest/v2/webhooks/incoming/...`. |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Disable Unify Circuit integration

Disable the Unify Circuit integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/unify-circuit
```

### Get Unify Circuit integration settings

Get Unify Circuit integration settings for a project.

```plaintext
GET /projects/:id/integrations/unify-circuit
```

## Pumble

Pumble chat tool.

### Create/Edit Pumble integration

Set Pumble integration for a project.

```plaintext
PUT /projects/:id/integrations/pumble
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Pumble webhook. For example, `https://api.pumble.com/workspaces/x/...`. |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default is `default`. |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events. |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events. |
| `issues_events` | boolean | false | Enable notifications for issue events. |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events. |
| `note_events` | boolean | false | Enable notifications for note events. |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines. |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events. |
| `push_events` | boolean | false | Enable notifications for push events. |
| `tag_push_events` | boolean | false | Enable notifications for tag push events. |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events. |

### Disable Pumble integration

Disable the Pumble integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/pumble
```

### Get Pumble integration settings

Get Pumble integration settings for a project.

```plaintext
GET /projects/:id/integrations/pumble
```

## Webex Teams

Webex Teams collaboration tool.

### Create/Edit Webex Teams integration

Set Webex Teams integration for a project.

```plaintext
PUT /projects/:id/integrations/webex-teams
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Webex Teams webhook. For example, `https://api.ciscospark.com/v1/webhooks/incoming/...`. |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Disable Webex Teams integration

Disable the Webex Teams integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/webex-teams
```

### Get Webex Teams integration settings

Get Webex Teams integration settings for a project.

```plaintext
GET /projects/:id/integrations/webex-teams
```

## Custom Issue Tracker

Custom issue tracker

### Create/Edit Custom Issue Tracker integration

Set Custom Issue Tracker integration for a project.

```plaintext
PUT /projects/:id/integrations/custom-issue-tracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true |  New Issue URL |
| `issues_url` | string | true | Issue URL |
| `project_url` | string | true | Project URL |

### Disable Custom Issue Tracker integration

Disable the Custom Issue Tracker integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/custom-issue-tracker
```

### Get Custom Issue Tracker integration settings

Get Custom Issue Tracker integration settings for a project.

```plaintext
GET /projects/:id/integrations/custom-issue-tracker
```

## Discord

Send notifications about project events to a Discord channel.

### Create/Edit Discord integration

Set Discord integration for a project.

```plaintext
PUT /projects/:id/integrations/discord
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | Discord webhook. For example, `https://discord.com/api/webhooks/…` |

### Disable Discord integration

Disable the Discord integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/discord
```

### Get Discord integration settings

Get Discord integration settings for a project.

```plaintext
GET /projects/:id/integrations/discord
```

## Drone CI

Drone is a Continuous Integration platform built on Docker, written in Go

### Create/Edit Drone CI integration

Set Drone CI integration for a project.

```plaintext
PUT /projects/:id/integrations/drone-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | Drone CI project specific token |
| `drone_url` | string | true | `http://drone.example.com` |
| `enable_ssl_verification` | boolean | false | Enable SSL verification. Defaults to true (enabled). |
| `push_events` | boolean | false | Enable notifications for push events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |

### Disable Drone CI integration

Disable the Drone CI integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/drone-ci
```

### Get Drone CI integration settings

Get Drone CI integration settings for a project.

```plaintext
GET /projects/:id/integrations/drone-ci
```

## Emails on Push

Email the commits and diff of each push to a list of recipients.

### Create/Edit Emails on Push integration

Set Emails on Push integration for a project.

```plaintext
PUT /projects/:id/integrations/emails-on-push
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | true | Emails separated by whitespace |
| `disable_diffs` | boolean | false | Disable code diffs |
| `send_from_committer_email` | boolean | false | Send from committer |
| `push_events` | boolean | false | Enable notifications for push events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. Notifications are always fired for tag pushes. The default value is "all" |

### Disable Emails on Push integration

Disable the Emails on Push integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/emails-on-push
```

### Get Emails on Push integration settings

Get Emails on Push integration settings for a project.

```plaintext
GET /projects/:id/integrations/emails-on-push
```

## Engineering Workflow Management (EWM)

Use IBM Engineering Workflow Management (EWM) as a project's issue tracker.

### Create/Edit EWM integration

Set EWM integration for a project.

```plaintext
PUT /projects/:id/integrations/ewm
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true | The URL to create an issue in EWM |
| `project_url`   | string | true | The URL to the project in EWM |
| `issues_url`    | string | true | The URL to view an issue in EWM. Must contain `:id` |

### Disable EWM integration

Disable the EWM integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/ewm
```

### Get EWM integration settings

Get EWM integration settings for a project.

```plaintext
GET /projects/:id/integrations/ewm
```

## Confluence integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220934) in GitLab 13.2.

Replaces the link to the internal wiki with a link to a Confluence Cloud Workspace.

### Create/Edit Confluence integration

Set Confluence integration for a project.

```plaintext
PUT /projects/:id/integrations/confluence
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | string | true | The URL of the Confluence Cloud Workspace hosted on atlassian.net.  |

### Disable Confluence integration

Disable the Confluence integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/confluence
```

### Get Confluence integration settings

Get Confluence integration settings for a project.

```plaintext
GET /projects/:id/integrations/confluence
```

## Shimo integration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343386) in GitLab 14.5 [with a flag](../administration/feature_flags.md) named `shimo_integration`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/343386) in GitLab 15.4.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/343386) in GitLab 15.4. [Feature flag `shimo_integration`](https://gitlab.com/gitlab-org/gitlab/-/issues/345356) removed.

Replaces the link to the internal wiki with a link to a Shimo Workspace.

### Create/Edit Shimo integration

Set Shimo integration for a project.

```plaintext
PUT /projects/:id/integrations/shimo
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | string | true | Shimo Workspace URL  |

### Disable Shimo integration

Disable the Shimo integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/shimo
```

## External wiki

Replaces the link to the internal wiki with a link to an external wiki.

### Create/Edit External wiki integration

Set External wiki integration for a project.

```plaintext
PUT /projects/:id/integrations/external-wiki
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | string | true | The URL of the external wiki |

### Disable External wiki integration

Disable the External wiki integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/external-wiki
```

### Get External wiki integration settings

Get External wiki integration settings for a project.

```plaintext
GET /projects/:id/integrations/external-wiki
```

## GitHub **(PREMIUM)**

Code collaboration software.

### Create/Edit GitHub integration

Set GitHub integration for a project.

```plaintext
PUT /projects/:id/integrations/github
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | GitHub API token with `repo:status` OAuth scope |
| `repository_url` | string | true | GitHub repository URL |
| `static_context` | boolean | false | Append instance name instead of branch to [status check name](../user/project/integrations/github.md#static-or-dynamic-status-check-names) |

### Disable GitHub integration

Disable the GitHub integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/github
```

### Get GitHub integration settings

Get GitHub integration settings for a project.

```plaintext
GET /projects/:id/integrations/github
```

## Hangouts Chat

Google Workspace team collaboration tool.

### Create/Edit Hangouts Chat integration

Set Hangouts Chat integration for a project.

```plaintext
PUT /projects/:id/integrations/hangouts-chat
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Hangouts Chat webhook. For example, `https://chat.googleapis.com/v1/spaces...`. |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Disable Hangouts Chat integration

Disable the Hangouts Chat integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/hangouts-chat
```

### Get Hangouts Chat integration settings

Get Hangouts Chat integration settings for a project.

```plaintext
GET /projects/:id/integrations/hangouts-chat
```

## Irker (IRC gateway)

Send IRC messages, on update, to a list of recipients through an irker gateway.

For more information, see the [irker integration documentation](../user/project/integrations/irker.md).

### Create/Edit Irker (IRC gateway) integration

Set Irker (IRC gateway) integration for a project.

```plaintext
PUT /projects/:id/integrations/irker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | true | Recipients/channels separated by whitespaces |
| `default_irc_uri` | string | false | `irc://irc.network.net:6697/` |
| `server_host` | string | false | localhost |
| `server_port` | integer | false | 6659 |
| `colorize_messages` | boolean | false | Colorize messages |

### Disable Irker (IRC gateway) integration

Disable the Irker (IRC gateway) integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/irker
```

### Get Irker (IRC gateway) integration settings

Get Irker (IRC gateway) integration settings for a project.

```plaintext
GET /projects/:id/integrations/irker
```

## Jira

Jira issue tracker.

### Get Jira integration settings

Get Jira integration settings for a project.

```plaintext
GET /projects/:id/integrations/jira
```

### Create/Edit Jira integration

Set Jira integration for a project.

```plaintext
PUT /projects/:id/integrations/jira
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `url`           | string | yes | The URL to the Jira project which is being linked to this GitLab project. For example, `https://jira.example.com`. |
| `api_url`   | string | no | The base URL to the Jira instance API. Web URL value is used if not set. For example, `https://jira-api.example.com`. |
| `username`      | string | yes  | The username of the user created to be used with GitLab/Jira. |
| `password`      | string | yes  | The password of the user created to be used with GitLab/Jira. |
| `active`        | boolean | no  | Activates or deactivates the integration. Defaults to false (deactivated). |
| `jira_issue_prefix` | string | no | Prefix to match Jira issue keys. |
| `jira_issue_regex` | string | no | Regular expression to match Jira issue keys. |
| `jira_issue_transition_automatic` | boolean | no | Enable [automatic issue transitions](../integration/jira/issues.md#automatic-issue-transitions). Takes precedence over `jira_issue_transition_id` if enabled. Defaults to `false` |
| `jira_issue_transition_id` | string | no | The ID of one or more transitions for [custom issue transitions](../integration/jira/issues.md#custom-issue-transitions). Ignored if `jira_issue_transition_automatic` is enabled. Defaults to a blank string, which disables custom transitions. |
| `commit_events` | boolean | false | Enable notifications for commit events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `comment_on_event_enabled` | boolean | false | Enable comments inside Jira issues on each GitLab event (commit / merge request) |

### Disable Jira integration

Disable the Jira integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/jira
```

## Slack Slash Commands

Ability to receive slash commands from a Slack chat instance.

### Get Slack Slash Command integration settings

Get Slack Slash Command integration settings for a project.

```plaintext
GET /projects/:id/integrations/slack-slash-commands
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

### Create/Edit Slack Slash Commands integration

Set Slack Slash Command for a project.

```plaintext
PUT /projects/:id/integrations/slack-slash-commands
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Slack token |

### Disable Slack Slash Command integration

Disable the Slack Slash Command integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/slack-slash-commands
```

## Mattermost Slash Commands

Ability to receive slash commands from a Mattermost chat instance.

### Get Mattermost Slash Command integration settings

Get Mattermost Slash Command integration settings for a project.

```plaintext
GET /projects/:id/integrations/mattermost-slash-commands
```

### Create/Edit Mattermost Slash Command integration

Set Mattermost Slash Command for a project.

```plaintext
PUT /projects/:id/integrations/mattermost-slash-commands
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Mattermost token |

### Disable Mattermost Slash Command integration

Disable the Mattermost Slash Command integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/mattermost-slash-commands
```

## Packagist

Update your project on Packagist (the main Composer repository) when commits or tags are pushed to GitLab.

### Create/Edit Packagist integration

Set Packagist integration for a project.

```plaintext
PUT /projects/:id/integrations/packagist
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

### Disable Packagist integration

Disable the Packagist integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/packagist
```

### Get Packagist integration settings

Get Packagist integration settings for a project.

```plaintext
GET /projects/:id/integrations/packagist
```

## Pipeline-Emails

Get emails for GitLab CI/CD pipelines.

### Create/Edit Pipeline-Emails integration

Set Pipeline-Emails integration for a project.

```plaintext
PUT /projects/:id/integrations/pipelines-email
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | yes | Comma-separated list of recipient email addresses |
| `notify_only_broken_pipelines` | boolean | no | Notify only broken pipelines |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is "default" |
| `notify_only_default_branch` | boolean | no | Send notifications only for the default branch ([introduced in GitLab 12.0](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/28271)) |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |

### Disable Pipeline-Emails integration

Disable the Pipeline-Emails integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/pipelines-email
```

### Get Pipeline-Emails integration settings

Get Pipeline-Emails integration settings for a project.

```plaintext
GET /projects/:id/integrations/pipelines-email
```

## Pivotal Tracker

Add commit messages as comments to Pivotal Tracker stories.

See also the [Pivotal Tracker integration documentation](../user/project/integrations/pivotal_tracker.md).

### Create/Edit Pivotal Tracker integration

Set Pivotal Tracker integration for a project.

```plaintext
PUT /projects/:id/integrations/pivotaltracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | true | The Pivotal Tracker token |
| `restrict_to_branch` | boolean | false | Comma-separated list of branches to automatically inspect. Leave blank to include all branches. |

### Disable Pivotal Tracker integration

Disable the Pivotal Tracker integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/pivotaltracker
```

### Get Pivotal Tracker integration settings

Get Pivotal Tracker integration settings for a project.

```plaintext
GET /projects/:id/integrations/pivotaltracker
```

## Prometheus

Prometheus is a powerful time-series monitoring service.

### Create/Edit Prometheus integration

Set Prometheus integration for a project.

```plaintext
PUT /projects/:id/integrations/prometheus
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_url` | string | true | Prometheus API Base URL. For example, `http://prometheus.example.com/`. |
| `google_iap_audience_client_id` | string | false | Client ID of the IAP secured resource (looks like IAP_CLIENT_ID.apps.googleusercontent.com) |
| `google_iap_service_account_json` | string | false | `credentials.json` file for your service account, like { `"type": "service_account", "project_id": ... }` |

### Disable Prometheus integration

Disable the Prometheus integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/prometheus
```

### Get Prometheus integration settings

Get Prometheus integration settings for a project.

```plaintext
GET /projects/:id/integrations/prometheus
```

## Pushover

Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop.

### Create/Edit Pushover integration

Set Pushover integration for a project.

```plaintext
PUT /projects/:id/integrations/pushover
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | true | Your application key |
| `user_key` | string | true | Your user key |
| `priority` | string | true | The priority |
| `device` | string | false | Leave blank for all active devices |
| `sound` | string | false | The sound of the notification |

### Disable Pushover integration

Disable the Pushover integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/pushover
```

### Get Pushover integration settings

Get Pushover integration settings for a project.

```plaintext
GET /projects/:id/integrations/pushover
```

## Redmine

Redmine issue tracker

### Create/Edit Redmine integration

Set Redmine integration for a project.

```plaintext
PUT /projects/:id/integrations/redmine
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | true | New Issue URL |
| `project_url` | string | true | Project URL |
| `issues_url` | string | true | Issue URL |

### Disable Redmine integration

Disable the Redmine integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/redmine
```

### Get Redmine integration settings

Get Redmine integration settings for a project.

```plaintext
GET /projects/:id/integrations/redmine
```

## Slack notifications

Receive event notifications in Slack

### Create/Edit Slack integration

Set Slack integration for a project.

```plaintext
PUT /projects/:id/integrations/slack
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | `https://hooks.slack.com/services/...` |
| `username` | string | false | username |
| `channel` | string | false | Default channel to use if others are not configured |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is "default" |
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

### Disable Slack integration

Disable the Slack integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/slack
```

### Get Slack integration settings

Get Slack integration settings for a project.

```plaintext
GET /projects/:id/integrations/slack
```

## Microsoft Teams

Group Chat Software

### Create/Edit Microsoft Teams integration

Set Microsoft Teams integration for a project.

```plaintext
PUT /projects/:id/integrations/microsoft-teams
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Microsoft Teams webhook. For example, `https://outlook.office.com/webhook/...` |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is "default" |
| `push_events` | boolean | false | Enable notifications for push events |
| `issues_events` | boolean | false | Enable notifications for issue events |
| `confidential_issues_events` | boolean | false | Enable notifications for confidential issue events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |
| `tag_push_events` | boolean | false | Enable notifications for tag push events |
| `note_events` | boolean | false | Enable notifications for note events |
| `confidential_note_events` | boolean | false | Enable notifications for confidential note events |
| `pipeline_events` | boolean | false | Enable notifications for pipeline events |
| `wiki_page_events` | boolean | false | Enable notifications for wiki page events |

### Disable Microsoft Teams integration

Disable the Microsoft Teams integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/microsoft-teams
```

### Get Microsoft Teams integration settings

Get Microsoft Teams integration settings for a project.

```plaintext
GET /projects/:id/integrations/microsoft-teams
```

## Mattermost notifications

Receive event notifications in Mattermost

### Create/Edit Mattermost notifications integration

Set Mattermost notifications integration for a project.

```plaintext
PUT /projects/:id/integrations/mattermost
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | true | The Mattermost webhook. For example, `http://mattermost_host/hooks/...` |
| `username` | string | false | username |
| `channel` | string | false | Default channel to use if others are not configured |
| `notify_only_broken_pipelines` | boolean | false | Send notifications for broken pipelines |
| `notify_only_default_branch` | boolean | false | DEPRECATED: This parameter has been replaced with `branches_to_be_notified` |
| `branches_to_be_notified` | string | false | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is "default" |
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

### Disable Mattermost notifications integration

Disable the Mattermost notifications integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/mattermost
```

### Get Mattermost notifications integration settings

Get Mattermost notifications integration settings for a project.

```plaintext
GET /projects/:id/integrations/mattermost
```

## JetBrains TeamCity CI

A continuous integration and build server

### Create/Edit JetBrains TeamCity CI integration

Set JetBrains TeamCity CI integration for a project.

> The build configuration in TeamCity must use the build format number `%build.vcs.number%`. Configure monitoring of all branches so merge requests build. That setting is in the VSC root advanced settings.

```plaintext
PUT /projects/:id/integrations/teamcity
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | string | true | TeamCity root URL. For example, `https://teamcity.example.com` |
| `enable_ssl_verification` | boolean | false | Enable SSL verification. Defaults to true (enabled). |
| `build_type` | string | true | Build configuration ID |
| `username` | string | true | A user with permissions to trigger a manual build |
| `password` | string | true | The password of the user |
| `push_events` | boolean | false | Enable notifications for push events |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events |

### Disable JetBrains TeamCity CI integration

Disable the JetBrains TeamCity CI integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/teamcity
```

### Get JetBrains TeamCity CI integration settings

Get JetBrains TeamCity CI integration settings for a project.

```plaintext
GET /projects/:id/integrations/teamcity
```

## Jenkins CI

A continuous integration and build server

### Create/Edit Jenkins CI integration

Set Jenkins CI integration for a project.

```plaintext
PUT /projects/:id/integrations/jenkins
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `jenkins_url` | string | true | Jenkins URL like `http://jenkins.example.com`. |
| `enable_ssl_verification` | boolean | false | Enable SSL verification. Defaults to true (enabled). |
| `project_name` | string | true | The URL-friendly project name. Example: `my_project_name`. |
| `username` | string | false | Username for authentication with the Jenkins server, if authentication is required by the server. |
| `password` | string | false | Password for authentication with the Jenkins server, if authentication is required by the server. |
| `push_events` | boolean | false | Enable notifications for push events. |
| `merge_requests_events` | boolean | false | Enable notifications for merge request events. |
| `tag_push_events` | boolean | false | Enable notifications for tag push events. |

### Disable Jenkins CI integration

Disable the Jenkins CI integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/jenkins
```

### Get Jenkins CI integration settings

Get Jenkins CI integration settings for a project.

```plaintext
GET /projects/:id/integrations/jenkins
```

## Jenkins CI (Deprecated) integration

A continuous integration and build server

NOTE:
This integration was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/1600) in GitLab 13.0.

### Create/Edit Jenkins CI (Deprecated) integration

Set Jenkins CI (Deprecated) integration for a project.

```plaintext
PUT /projects/:id/integrations/jenkins-deprecated
```

Parameters:

- `project_url` (**required**) - Jenkins project URL like `http://jenkins.example.com/job/my-project/`
- `multiproject_enabled` (optional) - Multi-project mode is configured in Jenkins GitLab Hook plugin
- `pass_unstable` (optional) - Unstable builds are treated as passing

### Disable Jenkins CI (Deprecated) integration

Disable the Jenkins CI (Deprecated) integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/jenkins-deprecated
```

### Get Jenkins CI (Deprecated) integration settings

Get Jenkins CI (Deprecated) integration settings for a project.

```plaintext
GET /projects/:id/integrations/jenkins-deprecated
```

## MockCI

Mock an external CI. See [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service) for an example of a companion mock integration.

This integration is only available when your environment is set to development.

### Create/Edit MockCI integration

Set MockCI integration for a project.

```plaintext
PUT /projects/:id/integrations/mock-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | string | true | `http://localhost:4004` |
| `enable_ssl_verification` | boolean | false | Enable SSL verification. Defaults to true (enabled). |

### Disable MockCI integration

Disable the MockCI integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/mock-ci
```

### Get MockCI integration settings

Get MockCI integration settings for a project.

```plaintext
GET /projects/:id/integrations/mock-ci
```

## Squash TM

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/337855) in GitLab 15.10.

Update [Squash TM](https://www.squashtest.com/product-squash-tm?lang=en) requirements when GitLab issues are modified.

### Create/Edit Squash TM integration

Set Squash TM integration settings for a project.

```plaintext
PUT /projects/:id/integrations/squash-tm
```

Parameters:

| Parameter               | Type   | Required | Description                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | string | yes      | URL of the Squash TM webhook. |
| `token`                 | string | no       | Optional token                |

### Disable Squash TM integration

Disable the Squash TM integration for a project. Integration settings are preserved.

```plaintext
DELETE /projects/:id/integrations/squash-tm
```

### Get Squash TM integration settings

Get Squash TM integration settings for a project.

```plaintext
GET /projects/:id/integrations/squash-tm
```

## YouTrack

YouTrack issue tracker

### Create/Edit YouTrack integration

Set YouTrack integration for a project.

```plaintext
PUT /projects/:id/integrations/youtrack
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `issues_url` | string | true | Issue URL |
| `project_url` | string | true | Project URL |

### Disable YouTrack integration

Disable the YouTrack integration for a project. Integration settings are reset.

```plaintext
DELETE /projects/:id/integrations/youtrack
```

### Get YouTrack integration settings

Get YouTrack integration settings for a project.

```plaintext
GET /projects/:id/integrations/youtrack
```
