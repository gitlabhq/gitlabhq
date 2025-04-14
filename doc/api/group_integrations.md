---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group integrations API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328496) in GitLab 17.9.

{{< /history >}}

Use this API to work with external services that integrate with GitLab.

This API requires an access token with at least the Maintainer role.

## List all active integrations

Get a list of all active group integrations. The `vulnerability_events` field is only available for GitLab Enterprise Edition.

```plaintext
GET /groups/:id/integrations
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
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": false,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
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
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": true,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
  }
]
```

## Asana

### Set up Asana

Set up the Asana integration for a group.

```plaintext
PUT /groups/:id/integrations/asana
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | yes | User API token. The user must have access to the task. All comments are attributed to this user. |
| `restrict_to_branch` | string | no | Comma-separated list of branches to be automatically inspected. Leave blank to include all branches. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Asana

Disable the Asana integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/asana
```

### Get Asana settings

Get the Asana integration settings for a group.

```plaintext
GET /groups/:id/integrations/asana
```

## Assembla

### Set up Assembla

Set up the Assembla integration for a group.

```plaintext
PUT /groups/:id/integrations/assembla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The authentication token. |
| `subdomain` | string | no | The subdomain setting. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Assembla

Disable the Assembla integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/assembla
```

### Get Assembla settings

Get the Assembla integration settings for a group.

```plaintext
GET /groups/:id/integrations/assembla
```

## Atlassian Bamboo

### Set up Atlassian Bamboo

Set up the Atlassian Bamboo integration for a group.

You must configure automatic revision labeling and a repository trigger in Bamboo.

```plaintext
PUT /groups/:id/integrations/bamboo
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | string | yes | Bamboo root URL (for example, `https://bamboo.example.com`). |
| `enable_ssl_verification` | boolean | no | Enable SSL verification. Defaults to `true` (enabled). |
| `build_key` | string | yes | Bamboo build plan key (for example, `KEY`). |
| `username` | string | yes | User with API access to the Bamboo server. |
| `password` | string | yes | Password of the user. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Atlassian Bamboo

Disable the Atlassian Bamboo integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/bamboo
```

### Get Atlassian Bamboo settings

Get the Atlassian Bamboo integration settings for a group.

```plaintext
GET /groups/:id/integrations/bamboo
```

## Bugzilla

### Set up Bugzilla

Set up the Bugzilla integration for a group.

```plaintext
PUT /groups/:id/integrations/bugzilla
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | yes |  URL of the new issue. |
| `issues_url` | string | yes | URL of the issue. |
| `project_url` | string | yes | URL of the project. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Bugzilla

Disable the Bugzilla integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/bugzilla
```

### Get Bugzilla settings

Get the Bugzilla integration settings for a group.

```plaintext
GET /groups/:id/integrations/bugzilla
```

## Buildkite

### Set up Buildkite

Set up the Buildkite integration for a group.

```plaintext
PUT /groups/:id/integrations/buildkite
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | Buildkite project GitLab token. |
| `project_url` | string | yes | Pipeline URL (for example, `https://buildkite.com/example/pipeline`). |
| `enable_ssl_verification` | boolean | no | **Deprecated:** This parameter has no effect because SSL verification is always enabled. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Buildkite

Disable the Buildkite integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/buildkite
```

### Get Buildkite settings

Get the Buildkite integration settings for a group.

```plaintext
GET /groups/:id/integrations/buildkite
```

## Campfire Classic

You can integrate with Campfire Classic. However, Campfire Classic is an old product that is
[no longer sold](https://gitlab.com/gitlab-org/gitlab/-/issues/329337) by Basecamp.

### Set up Campfire Classic

Set up the Campfire Classic integration for a group.

```plaintext
PUT /groups/:id/integrations/campfire
```

Parameters:

| Parameter     | Type    | Required | Description                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | string  | yes     | API authentication token from Campfire Classic. To get the token, sign in to Campfire Classic and select **My info**. |
| `subdomain`   | string  | no    | `.campfirenow.com` subdomain when you're signed in. |
| `room`        | string  | no    | ID portion of the Campfire Classic room URL. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Campfire Classic

Disable the Campfire Classic integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/campfire
```

### Get Campfire Classic settings

Get the Campfire Classic integration settings for a group.

```plaintext
GET /groups/:id/integrations/campfire
```

## ClickUp

### Set up ClickUp

Set up the ClickUp integration for a group.

```plaintext
PUT /groups/:id/integrations/clickup
```

Parameters:

| Parameter     | Type   | Required | Description    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | string | yes     | URL of the issue.     |
| `project_url` | string | yes     | URL of the project.   |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable ClickUp

Disable the ClickUp integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/clickup
```

### Get ClickUp settings

Get the ClickUp integration settings for a group.

```plaintext
GET /groups/:id/integrations/clickup
```

## Confluence Workspace

### Set up Confluence Workspace

Set up the Confluence Workspace integration for a group.

```plaintext
PUT /groups/:id/integrations/confluence
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | string | yes | URL of the Confluence Workspace hosted on `atlassian.net`. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Confluence Workspace

Disable the Confluence Workspace integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/confluence
```

### Get Confluence Workspace settings

Get the Confluence Workspace integration settings for a group.

```plaintext
GET /groups/:id/integrations/confluence
```

## Custom issue tracker

### Set up a custom issue tracker

Set up a custom issue tracker for a group.

```plaintext
PUT /groups/:id/integrations/custom-issue-tracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | yes |  URL of the new issue. |
| `issues_url` | string | yes | URL of the issue. |
| `project_url` | string | yes | URL of the project. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable a custom issue tracker

Disable a custom issue tracker for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/custom-issue-tracker
```

### Get custom issue tracker settings

Get the custom issue tracker settings for a group.

```plaintext
GET /groups/:id/integrations/custom-issue-tracker
```

## Datadog

### Set up Datadog

Set up the Datadog integration for a group.

```plaintext
PUT /groups/:id/integrations/datadog
```

Parameters:

| Parameter              | Type    | Required | Description                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | string  | yes     | API key used for authentication with Datadog.                                                                                                                                          |
| `api_url`              | string  | no    | (Advanced) The full URL for your Datadog site.                                                                                                                                          |
| `datadog_env`          | string  | no    | For self-managed deployments, set the `env%` tag for all the data sent to Datadog.                                                                                                      |
| `datadog_service`      | string  | no    | Tag all data from this GitLab instance in Datadog. Can be used when managing several self-managed deployments.                                                                          |
| `datadog_site`         | string  | no    | The Datadog site to send data to. To send data to the EU site, use `datadoghq.eu`.                                                                                                      |
| `datadog_tags`         | string  | no    | Custom tags in Datadog. Specify one tag per line in the format `key:value\nkey2:value2`                                                                                                 |
| `archive_trace_events` | boolean | no    | When enabled, job logs are collected by Datadog and displayed along with pipeline execution traces. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Datadog

Disable the Datadog integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/datadog
```

### Get Datadog settings

Get the Datadog integration settings for a group.

```plaintext
GET /groups/:id/integrations/datadog
```

## Diffblue Cover

### Set up Diffblue Cover

Set up the Diffblue Cover integration for a group.

```plaintext
PUT /groups/:id/integrations/diffblue-cover
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | string | yes | Diffblue Cover license key. |
| `diffblue_access_token_name` | string | yes | Access token name used by Diffblue Cover in pipelines. |
| `diffblue_access_token_secret` | string  | yes | Access token secret used by Diffblue Cover in pipelines. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Diffblue Cover

Disable the Diffblue Cover integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/diffblue-cover
```

### Get Diffblue Cover settings

Get the Diffblue Cover integration settings for a group.

```plaintext
GET /groups/:id/integrations/diffblue-cover
```

## Discord Notifications

### Set up Discord Notifications

Set up Discord Notifications for a group.

```plaintext
PUT /groups/:id/integrations/discord
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | Discord webhook (for example, `https://discord.com/api/webhooks/...`). |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `confidential_issue_channel` | string | no | The webhook override to receive notifications for confidential issue events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `confidential_note_channel` | string | no | The webhook override to receive notifications for confidential note events. |
| `deployment_events` | boolean | no | Enable notifications for deployment events. |
| `deployment_channel` | string | no | The webhook override to receive notifications for deployment events. |
| `group_confidential_mentions_events` | boolean | no | Enable notifications for group confidential mention events. |
| `group_confidential_mentions_channel` | string | no | The webhook override to receive notifications for group confidential mention events. |
| `group_mentions_events` | boolean | no | Enable notifications for group mention events. |
| `group_mentions_channel` | string | no | The webhook override to receive notifications for group mention events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `issue_channel` | string | no | The webhook override to receive notifications for issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `merge_request_channel` | string | no | The webhook override to receive notifications for merge request events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `note_channel` | string | no | The webhook override to receive notifications for note events. |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `pipeline_channel` | string | no | The webhook override to receive notifications for pipeline events. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `push_channel` | string | no | The webhook override to receive notifications for push events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `tag_push_channel` | string | no | The webhook override to receive notifications for tag push events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `wiki_page_channel` | string | no | The webhook override to receive notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Discord Notifications

Disable Discord Notifications for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/discord
```

### Get Discord Notifications settings

Get the Discord Notifications settings for a group.

```plaintext
GET /groups/:id/integrations/discord
```

## Drone

### Set up Drone

Set up the Drone integration for a group.

```plaintext
PUT /groups/:id/integrations/drone-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | Drone CI project specific token. |
| `drone_url` | string | yes | `http://drone.example.com`. |
| `enable_ssl_verification` | boolean | no | Enable SSL verification. Defaults to `true` (enabled). |
| `push_events` | boolean | no | Enable notifications for push events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Drone

Disable the Drone integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/drone-ci
```

### Get Drone settings

Get the Drone integration settings for a group.

```plaintext
GET /groups/:id/integrations/drone-ci
```

## Emails on push

### Set up emails on push

Set up the emails on push integration for a group.

```plaintext
PUT /groups/:id/integrations/emails-on-push
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | yes | Emails separated by whitespace. |
| `disable_diffs` | boolean | no | Disable code diffs. |
| `send_from_committer_email` | boolean | no | Send from committer. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. Notifications are always fired for tag pushes. The default value is `all`. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable emails on push

Disable the emails on push integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/emails-on-push
```

### Get emails on push settings

Get the emails on push integration settings for a group.

```plaintext
GET /groups/:id/integrations/emails-on-push
```

## Engineering Workflow Management (EWM)

### Set up EWM

Set up the EWM integration for a group.

```plaintext
PUT /groups/:id/integrations/ewm
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | yes | URL of the new issue. |
| `project_url`   | string | yes | URL of the project. |
| `issues_url`    | string | yes | URL of the issue. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable EWM

Disable the EWM integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/ewm
```

### Get EWM settings

Get the EWM integration settings for a group.

```plaintext
GET /groups/:id/integrations/ewm
```

## External wiki

### Set up an external wiki

Set up an external wiki for a group.

```plaintext
PUT /groups/:id/integrations/external-wiki
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | string | yes | URL of the external wiki. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable an external wiki

Disable an external wiki for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/external-wiki
```

### Get external wiki settings

Get the external wiki settings for a group.

```plaintext
GET /groups/:id/integrations/external-wiki
```

## GitGuardian

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="flag" >}}

On GitLab Self-Managed, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../administration/feature_flags.md) named `git_guardian_integration`.
On GitLab.com, this feature is not available. On GitLab Dedicated, this feature is available.

{{< /alert >}}

[GitGuardian](https://www.gitguardian.com/) is a cybersecurity service that detects sensitive data such as API keys
and passwords in source code repositories.
It scans Git repositories, alerts on policy violations, and helps organizations
fix security issues before hackers can exploit them.

You can configure GitLab to reject commits based on GitGuardian policies.

### Known issues

- Pushes can be delayed or can time out. With the GitGuardian integration, pushes are sent to a third-party, and GitLab has no control over the connection with GitGuardian or the GitGuardian process.
- Due to a [GitGuardian API limitation](https://api.gitguardian.com/docs#operation/multiple_scan), the integration ignores files over the size of 1 MB. They are not scanned.
- If a pushed file has a name over 256 characters long the push won't go through.
  For more information, see [GitGuardian API documentation](https://api.gitguardian.com/docs#operation/multiple_scan) .

Troubleshooting steps on [the integration page](../user/project/integrations/git_guardian.md#troubleshooting)
show how to mitigate some of these problems.

### Set up GitGuardian

Set up the GitGuardian integration for a group.

```plaintext
PUT /groups/:id/integrations/git-guardian
```

Parameters:

| Parameter | Type | Required | Description                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | string | yes | GitGuardian API token with `scan` scope. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable GitGuardian

Disable the GitGuardian integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/git-guardian
```

### Get GitGuardian settings

Get the GitGuardian integration settings for a group.

```plaintext
GET /groups/:id/integrations/git-guardian
```

## GitHub

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

### Set up GitHub

Set up the GitHub integration for a group.

```plaintext
PUT /groups/:id/integrations/github
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | GitHub API token with `repo:status` OAuth scope. |
| `repository_url` | string | yes | GitHub repository URL. |
| `static_context` | boolean | no | Append the hostname of your GitLab instance to the [status check name](../user/project/integrations/github.md#static-or-dynamic-status-check-names). |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable GitHub

Disable the GitHub integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/github
```

### Get GitHub settings

Get the GitHub integration settings for a group.

```plaintext
GET /groups/:id/integrations/github
```

## GitLab for Jira Cloud app

The GitLab for Jira Cloud app integration is enabled or disabled automatically through [group linking and unlinking in Jira](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app). You cannot enable or disable the integration with the GitLab integrations form or the API.

### Update integration for a group

Use this API endpoint to update an integration you create with group linking in Jira.

```plaintext
PUT /groups/:id/integrations/jira-cloud-app
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | string | no | Jira Service Management Service IDs. Use commas (`,`) to separate multiple IDs. |
| `jira_cloud_app_enable_deployment_gating` | boolean | no | Enables deployment gating for blocked GitLab deployments from Jira Service Management. |
| `jira_cloud_app_deployment_gating_environments` | string | no | The environments (production, staging, testing, or development) to enable deployment gating. Required if deployment gating is enabled. Use commas (`,`) to separate multiple environments. |

### Get GitLab for Jira Cloud app settings

Get the GitLab for Jira Cloud app integration settings for a group.

```plaintext
GET /groups/:id/integrations/jira-cloud-app
```

## GitLab for Slack app

### Set up GitLab for Slack app

Update the GitLab for Slack app integration for a group.

You cannot create a GitLab for Slack app through the API because the integration
requires an OAuth 2.0 token that you cannot get from the GitLab API alone.
Instead, you must [install the app](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app) from the GitLab UI.
You can then use this API endpoint to update the integration.

```plaintext
PUT /groups/:id/integrations/gitlab-slack-application
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `channel` | string | no | Default channel to use if no other channel is configured. |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `notify_only_default_branch` | boolean | no | **Deprecated:** This parameter has been replaced with `branches_to_be_notified`. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `alert_events` | boolean | no | Enable notifications for alert events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `deployment_events` | boolean | no | Enable notifications for deployment events. |
| `incidents_events` | boolean | no | Enable notifications for incident events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `vulnerability_events` | boolean | no | Enable notifications for vulnerability events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `labels_to_be_notified` | string | no | Labels to send notifications for. If not set, receive notifications for all events. |
| `labels_to_be_notified_behavior` | string | no | Labels to be notified for. Valid options are `match_any` and `match_all`. Defaults to `match_any`. |
| `push_channel` | string | no | Name of the channel to receive notifications for push events. |
| `issue_channel` | string | no | Name of the channel to receive notifications for issue events. |
| `confidential_issue_channel` | string | no | Name of the channel to receive notifications for confidential issue events. |
| `merge_request_channel` | string | no | Name of the channel to receive notifications for merge request events. |
| `note_channel` | string | no | Name of the channel to receive notifications for note events. |
| `confidential_note_channel` | string | no | Name of the channel to receive notifications for confidential note events. |
| `tag_push_channel` | string | no | Name of the channel to receive notifications for tag push events. |
| `pipeline_channel` | string | no | Name of the channel to receive notifications for pipeline events. |
| `wiki_page_channel` | string | no | Name of the channel to receive notifications for wiki page events. |
| `deployment_channel` | string | no | Name of the channel to receive notifications for deployment events. |
| `incident_channel` | string | no | Name of the channel to receive notifications for incident events. |
| `vulnerability_channel` | string | no | Name of the channel to receive notifications for vulnerability events. |
| `alert_channel` | string | no | Name of the channel to receive notifications for alert events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable GitLab for Slack app

Disable the GitLab for Slack app integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/gitlab-slack-application
```

### Get GitLab for Slack app settings

Get the GitLab for Slack app integration settings for a group.

```plaintext
GET /groups/:id/integrations/gitlab-slack-application
```

## Google Chat

### Set up Google Chat

Set up the Google Chat integration for a group.

```plaintext
PUT /groups/:id/integrations/hangouts-chat
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | The Hangouts Chat webhook (for example, `https://chat.googleapis.com/v1/spaces...`). |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `notify_only_default_branch` | boolean | no | **Deprecated:** This parameter has been replaced with `branches_to_be_notified`. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Google Chat

Disable the Google Chat integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/hangouts-chat
```

### Get Google Chat settings

Get the Google Chat integration settings for a group.

```plaintext
GET /groups/:id/integrations/hangouts-chat
```

## Google Artifact Management

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

This feature is in [beta](../policy/experiment-beta-support.md).

### Set up Google Artifact Management

Set up the Google Artifact Management integration for a group.

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-artifact-registry
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | string | yes | ID of the Google Cloud project. |
| `artifact_registry_location` | string | yes | Location of the Artifact Registry repository. |
| `artifact_registry_repositories` | string | yes | Repository of Artifact Registry. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Google Artifact Management

Disable the Google Artifact Management integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-artifact-registry
```

### Get Google Artifact Management settings

Get the Google Artifact Management integration settings for a group.

```plaintext
GET /groups/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management (IAM)

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

This feature is in [beta](../policy/experiment-beta-support.md).

### Set up Google Cloud Identity and Access Management

Set up the Google Cloud Identity and Access Management integration for a group.

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | string | yes | Google Cloud project ID for the Workload Identity Federation. |
| `workload_identity_federation_project_number` | integer | yes | Google Cloud project number for the Workload Identity Federation. |
| `workload_identity_pool_id` | string | yes | ID of the Workload Identity Pool. |
| `workload_identity_pool_provider_id` | string | yes | ID of the Workload Identity Pool provider. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Google Cloud Identity and Access Management

Disable the Google Cloud Identity and Access Management integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Get Google Cloud Identity and Access Management

Get the settings for the Google Cloud Identity and Access Management for a group.

```plaintext
GET /groups/:id/integration/google-cloud-platform-workload-identity-federation
```

## Harbor

### Set up Harbor

Set up the Harbor integration for a group.

```plaintext
PUT /groups/:id/integrations/harbor
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `url` | string | yes | The base URL to the Harbor instance linked to the GitLab project. For example, `https://demo.goharbor.io`. |
| `project_name` | string | yes | The name of the project in the Harbor instance. For example, `testproject`. |
| `username` | string | yes | The username created in the Harbor interface. |
| `password` | string | yes | The password of the user. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Harbor

Disable the Harbor integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/harbor
```

### Get Harbor settings

Get the Harbor integration settings for a group.

```plaintext
GET /groups/:id/integrations/harbor
```

## irker (IRC gateway)

### Set up irker

Set up the irker integration for a group.

```plaintext
PUT /groups/:id/integrations/irker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | yes | Recipients or channels separated by whitespaces. |
| `default_irc_uri` | string | no | `irc://irc.network.net:6697/`. |
| `server_host` | string | no | localhost. |
| `server_port` | integer | no | 6659. |
| `colorize_messages` | boolean | no | Colorize messages. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable irker

Disable the irker integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/irker
```

### Get irker settings

Get the irker integration settings for a group.

```plaintext
GET /groups/:id/integrations/irker
```

## JetBrains TeamCity

### Set up JetBrains TeamCity

Set up the JetBrains TeamCity integration for a group.

The build configuration in TeamCity must use the build number format `%build.vcs.number%`.
In the advanced settings for VCS root, configure monitoring for all branches so merge requests can build.

```plaintext
PUT /groups/:id/integrations/teamcity
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | string | yes | TeamCity root URL (for example, `https://teamcity.example.com`). |
| `enable_ssl_verification` | boolean | no | Enable SSL verification. Defaults to `true` (enabled). |
| `build_type` | string | yes | Build configuration ID. |
| `username` | string | yes | A user with permissions to trigger a manual build. |
| `password` | string | yes | The password of the user. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable JetBrains TeamCity

Disable the JetBrains TeamCity integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/teamcity
```

### Get JetBrains TeamCity settings

Get the JetBrains TeamCity integration settings for a group.

```plaintext
GET /groups/:id/integrations/teamcity
```

## Jira

### Set up Jira

Set up the Jira integration for a group.

```plaintext
PUT /groups/:id/integrations/jira
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `url`           | string | yes | The URL to the Jira project which is being linked to this GitLab project (for example, `https://jira.example.com`). |
| `api_url`   | string | no | The base URL to the Jira instance API. Web URL value is used if not set (for example, `https://jira-api.example.com`). |
| `username`      | string | no   | The email or username to be used with Jira. For Jira Cloud use an email, for Jira Data Center and Jira Server use a username. Required when using Basic authentication (`jira_auth_type` is `0`). |
| `password`      | string | yes  | The Jira API token, password, or personal access token to be used with Jira. When your authentication method is basic (`jira_auth_type` is `0`), use an API token for Jira Cloud or a password for Jira Data Center or Jira Server. When your authentication method is a Jira personal access token (`jira_auth_type` is `1`), use the personal access token. |
| `active`        | boolean | no  | Activates or deactivates the integration. Defaults to `false` (deactivated). |
| `jira_auth_type`| integer | no  | The authentication method to be used with Jira. `0` means Basic Authentication. `1` means Jira personal access token. Defaults to `0`. |
| `jira_issue_prefix` | string | no | Prefix to match Jira issue keys. |
| `jira_issue_regex` | string | no | Regular expression to match Jira issue keys. |
| `jira_issue_transition_automatic` | boolean | no | Enable [automatic issue transitions](../integration/jira/issues.md#automatic-issue-transitions). Takes precedence over `jira_issue_transition_id` if enabled. Defaults to `false`. |
| `jira_issue_transition_id` | string | no | The ID of one or more transitions for [custom issue transitions](../integration/jira/issues.md#custom-issue-transitions). Ignored if `jira_issue_transition_automatic` is enabled. Defaults to a blank string, which disables custom transitions. |
| `commit_events` | boolean | no | Enable notifications for commit events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `comment_on_event_enabled` | boolean | no | Enable comments in Jira issues on each GitLab event (commit or merge request). |
| `issues_enabled` | boolean | no | Enable viewing Jira issues in GitLab. |
| `project_keys` | array of strings | no | Keys of Jira projects. When `issues_enabled` is `true`, this setting specifies which Jira projects to view issues from in GitLab. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Jira

Disable the Jira integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/jira
```

### Get Jira settings

Get the Jira integration settings for a group.

```plaintext
GET /groups/:id/integrations/jira
```

## Matrix notifications

### Set up Matrix notifications

Set up Matrix notifications for a group.

```plaintext
PUT /groups/:id/integrations/matrix
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `hostname`   | string | no | Custom hostname of the Matrix server. The default value is `https://matrix.org`. |
| `token`   | string | yes | The Matrix access token (for example, `syt-zyx57W2v1u123ew11`). |
| `room` | string | yes | Unique identifier for the target room (in the format `!qPKKM111FFKKsfoCVy:matrix.org`). |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Matrix notifications

Disable Matrix notifications for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/matrix
```

### Get Matrix notifications settings

Get the Matrix notifications settings for a group.

```plaintext
GET /groups/:id/integrations/matrix
```

## Mattermost notifications

### Set up Mattermost notifications

Set up Mattermost notifications for a group.

```plaintext
PUT /groups/:id/integrations/mattermost
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | Mattermost notifications webhook (for example, `http://mattermost.example.com/hooks/...`). |
| `username` | string | no | Mattermost notifications username. |
| `channel` | string | no | Default channel to use if no other channel is configured. |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `notify_only_default_branch` | boolean | no | **Deprecated:** This parameter has been replaced with `branches_to_be_notified`. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `labels_to_be_notified` | string | no | Labels to send notifications for. Leave blank to receive notifications for all events. |
| `labels_to_be_notified_behavior` | string | no | Labels to be notified for. Valid options are `match_any` and `match_all`. The default value is `match_any`. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `push_channel` | string | no | The name of the channel to receive notifications for push events. |
| `issue_channel` | string | no | The name of the channel to receive notifications for issue events. |
| `confidential_issue_channel` | string | no | The name of the channel to receive notifications for confidential issue events. |
| `merge_request_channel` | string | no | The name of the channel to receive notifications for merge request events. |
| `note_channel` | string | no | The name of the channel to receive notifications for note events. |
| `confidential_note_channel` | string | no | The name of the channel to receive notifications for confidential note events. |
| `tag_push_channel` | string | no | The name of the channel to receive notifications for tag push events. |
| `pipeline_channel` | string | no | The name of the channel to receive notifications for pipeline events. |
| `wiki_page_channel` | string | no | The name of the channel to receive notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Mattermost notifications

Disable Mattermost notifications for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/mattermost
```

### Get Mattermost notifications settings

Get the Mattermost notifications settings for a group.

```plaintext
GET /groups/:id/integrations/mattermost
```

## Mattermost slash commands

### Set up Mattermost slash commands

Set up Mattermost slash commands for a group.

```plaintext
PUT /groups/:id/integrations/mattermost-slash-commands
```

Parameters:

| Parameter | Type   | Required | Description           |
| --------- | ------ | -------- | --------------------- |
| `token`   | string | yes      | The Mattermost token. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Mattermost slash commands

Disable Mattermost slash commands for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/mattermost-slash-commands
```

### Get Mattermost slash commands settings

Get the Mattermost slash commands settings for a group.

```plaintext
GET /groups/:id/integrations/mattermost-slash-commands
```

## Microsoft Teams notifications

### Set up Microsoft Teams notifications

Set up Microsoft Teams notifications for a group.

```plaintext
PUT /groups/:id/integrations/microsoft-teams
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | The Microsoft Teams webhook (for example, `https://outlook.office.com/webhook/...`). |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `notify_only_default_branch` | boolean | no | **Deprecated:** This parameter has been replaced with `branches_to_be_notified`. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Microsoft Teams notifications

Disable Microsoft Teams notifications for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/microsoft-teams
```

### Get Microsoft Teams notifications settings

Get the Microsoft Teams notifications settings for a group.

```plaintext
GET /groups/:id/integrations/microsoft-teams
```

## Mock CI

This integration is only available in a development environment.
For an example Mock CI server, see [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service).

### Set up Mock CI

Set up the Mock CI integration for a group.

```plaintext
PUT /groups/:id/integrations/mock-ci
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | string | yes | URL of the Mock CI integration. |
| `enable_ssl_verification` | boolean | no | Enable SSL verification. Defaults to `true` (enabled). |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Mock CI

Disable the Mock CI integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/mock-ci
```

### Get Mock CI settings

Get the Mock CI integration settings for a group.

```plaintext
GET /groups/:id/integrations/mock-ci
```

## Packagist

### Set up Packagist

Set up the Packagist integration for a group.

```plaintext
PUT /groups/:id/integrations/packagist
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `username` | string | yes | The username of a Packagist account. |
| `token` | string | yes | API token to the Packagist server. |
| `server` | boolean | no | URL of the Packagist server. Leave blank for the default `<https://packagist.org>`. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Packagist

Disable the Packagist integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/packagist
```

### Get Packagist settings

Get the Packagist integration settings for a group.

```plaintext
GET /groups/:id/integrations/packagist
```

## Phorge

### Set up Phorge

Set up the Phorge integration for a group.

```plaintext
PUT /groups/:id/integrations/phorge
```

Parameters:

| Parameter       | Type   | Required | Description           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | string | yes     | URL of the issue.     |
| `project_url`   | string | yes     | URL of the project.   |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Phorge

Disable the Phorge integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/phorge
```

### Get Phorge settings

Get the Phorge integration settings for a group.

```plaintext
GET /groups/:id/integrations/phorge
```

## Pipeline status emails

### Set up pipeline status emails

Set up pipeline status emails for a group.

```plaintext
PUT /groups/:id/integrations/pipelines-email
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | yes | Comma-separated list of recipient email addresses. |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `notify_only_default_branch` | boolean | no | Send notifications for the default branch. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable pipeline status emails

Disable pipeline status emails for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/pipelines-email
```

### Get pipeline status emails settings

Get the pipeline status emails settings for a group.

```plaintext
GET /groups/:id/integrations/pipelines-email
```

## Pivotal Tracker

### Set up Pivotal Tracker

Set up the Pivotal Tracker integration for a group.

```plaintext
PUT /groups/:id/integrations/pivotaltracker
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Pivotal Tracker token. |
| `restrict_to_branch` | boolean | no | Comma-separated list of branches to automatically inspect. Leave blank to include all branches. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Pivotal Tracker

Disable the Pivotal Tracker integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/pivotaltracker
```

### Get Pivotal Tracker settings

Get the Pivotal Tracker integration settings for a group.

```plaintext
GET /groups/:id/integrations/pivotaltracker
```

## Pumble

### Set up Pumble

Set up the Pumble integration for a group.

```plaintext
PUT /groups/:id/integrations/pumble
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | The Pumble webhook (for example, `https://api.pumble.com/workspaces/x/...`). |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default is `default`. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Pumble

Disable the Pumble integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/pumble
```

### Get Pumble settings

Get the Pumble integration settings for a group.

```plaintext
GET /groups/:id/integrations/pumble
```

## Pushover

### Set up Pushover

Set up the Pushover integration for a group.

```plaintext
PUT /groups/:id/integrations/pushover
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | yes | Your application key. |
| `user_key` | string | yes | Your user key. |
| `priority` | string | yes | The priority. |
| `device` | string | no | Leave blank for all active devices. |
| `sound` | string | no | The sound of the notification. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Pushover

Disable the Pushover integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/pushover
```

### Get Pushover settings

Get the Pushover integration settings for a group.

```plaintext
GET /groups/:id/integrations/pushover
```

## Redmine

### Set up Redmine

Set up the Redmine integration for a group.

```plaintext
PUT /groups/:id/integrations/redmine
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | yes | URL of the new issue. |
| `project_url` | string | yes | URL of the project. |
| `issues_url` | string | yes | URL of the issue. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Redmine

Disable the Redmine integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/redmine
```

### Get Redmine settings

Get the Redmine integration settings for a group.

```plaintext
GET /groups/:id/integrations/redmine
```

## Slack notifications

### Set up Slack notifications

Set up Slack notifications for a group.

```plaintext
PUT /groups/:id/integrations/slack
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | Slack notifications webhook (for example, `https://hooks.slack.com/services/...`). |
| `username` | string | no | Slack notifications username. |
| `channel` | string | no | Default channel to use if no other channel is configured. |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `notify_only_default_branch` | boolean | no | **Deprecated:** This parameter has been replaced with `branches_to_be_notified`. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `labels_to_be_notified` | string | no | Labels to send notifications for. Leave blank to receive notifications for all events. |
| `labels_to_be_notified_behavior` | string | no | Labels to be notified for. Valid options are `match_any` and `match_all`. The default value is `match_any`. |
| `alert_channel` | string | no | The name of the channel to receive notifications for alert events. |
| `alert_events` | boolean | no | Enable notifications for alert events. |
| `commit_events` | boolean | no | Enable notifications for commit events. |
| `confidential_issue_channel` | string | no | The name of the channel to receive notifications for confidential issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `confidential_note_channel` | string | no | The name of the channel to receive notifications for confidential note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `deployment_channel` | string | no | The name of the channel to receive notifications for deployment events. |
| `deployment_events` | boolean | no | Enable notifications for deployment events. |
| `incident_channel` | string | no | The name of the channel to receive notifications for incident events. |
| `incidents_events` | boolean | no | Enable notifications for incident events. |
| `issue_channel` | string | no | The name of the channel to receive notifications for issue events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `job_events` | boolean | no | Enable notifications for job events. |
| `merge_request_channel` | string | no | The name of the channel to receive notifications for merge request events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `note_channel` | string | no | The name of the channel to receive notifications for note events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `pipeline_channel` | string | no | The name of the channel to receive notifications for pipeline events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `push_channel` | string | no | The name of the channel to receive notifications for push events. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `tag_push_channel` | string | no | The name of the channel to receive notifications for tag push events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `wiki_page_channel` | string | no | The name of the channel to receive notifications for wiki page events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Slack notifications

Disable Slack notifications for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/slack
```

### Get Slack notifications settings

Get the Slack notifications settings for a group.

```plaintext
GET /groups/:id/integrations/slack
```

## Slack slash commands

### Set up Slack slash commands

Set up Slack slash commands for a group.

```plaintext
PUT /groups/:id/integrations/slack-slash-commands
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | yes | The Slack token. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Slack slash commands

Disable Slack slash commands for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/slack-slash-commands
```

### Get Slack slash commands settings

Get the Slack slash commands settings for a group.

```plaintext
GET /groups/:id/integrations/slack-slash-commands
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
  "inherited": false,
  "properties": {
    "token": "<your_access_token>"
  }
}
```

## Squash TM

### Set up Squash TM

Set up the Squash TM integration settings for a group.

```plaintext
PUT /groups/:id/integrations/squash-tm
```

Parameters:

| Parameter               | Type   | Required | Description                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | string | yes      | URL of the Squash TM webhook. |
| `token`                 | string | no       | Secret token.                 |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Squash TM

Disable the Squash TM integration for a group. Integration settings are preserved.

```plaintext
DELETE /groups/:id/integrations/squash-tm
```

### Get Squash TM settings

Get the Squash TM integration settings for a group.

```plaintext
GET /groups/:id/integrations/squash-tm
```

## Telegram

### Set up Telegram

Set up the Telegram integration for a group.

```plaintext
PUT /groups/:id/integrations/telegram
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `hostname`   | string | no | Custom hostname of the Telegram API. The default value is `https://api.telegram.org`. |
| `token`   | string | yes | The Telegram bot token (for example, `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`). |
| `room` | string | yes | Unique identifier for the target chat or the username of the target channel (in the format `@channelusername`). |
| `thread` | integer | no | Unique identifier for the target message thread (topic in a forum supergroup). |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `push_events` | boolean | yes | Enable notifications for push events. |
| `issues_events` | boolean | yes | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | yes | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | yes | Enable notifications for merge request events. |
| `tag_push_events` | boolean | yes | Enable notifications for tag push events. |
| `note_events` | boolean | yes | Enable notifications for note events. |
| `confidential_note_events` | boolean | yes | Enable notifications for confidential note events. |
| `pipeline_events` | boolean | yes | Enable notifications for pipeline events. |
| `wiki_page_events` | boolean | yes | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Telegram

Disable the Telegram integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/telegram
```

### Get Telegram settings

Get the Telegram integration settings for a group.

```plaintext
GET /groups/:id/integrations/telegram
```

## Unify Circuit

### Set up Unify Circuit

Set up the Unify Circuit integration for a group.

```plaintext
PUT /groups/:id/integrations/unify-circuit
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | The Unify Circuit webhook (for example, `https://circuit.com/rest/v2/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Unify Circuit

Disable the Unify Circuit integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/unify-circuit
```

### Get Unify Circuit settings

Get the Unify Circuit integration settings for a group.

```plaintext
GET /groups/:id/integrations/unify-circuit
```

## Webex Teams

### Set up Webex Teams

Set up Webex Teams for a group.

```plaintext
PUT /groups/:id/integrations/webex-teams
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | yes | The Webex Teams webhook (for example, `https://api.ciscospark.com/v1/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | boolean | no | Send notifications for broken pipelines. |
| `branches_to_be_notified` | string | no | Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`. |
| `push_events` | boolean | no | Enable notifications for push events. |
| `issues_events` | boolean | no | Enable notifications for issue events. |
| `confidential_issues_events` | boolean | no | Enable notifications for confidential issue events. |
| `merge_requests_events` | boolean | no | Enable notifications for merge request events. |
| `tag_push_events` | boolean | no | Enable notifications for tag push events. |
| `note_events` | boolean | no | Enable notifications for note events. |
| `confidential_note_events` | boolean | no | Enable notifications for confidential note events. |
| `pipeline_events` | boolean | no | Enable notifications for pipeline events. |
| `wiki_page_events` | boolean | no | Enable notifications for wiki page events. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable Webex Teams

Disable Webex Teams for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/webex-teams
```

### Get Webex Teams settings

Get the Webex Teams settings for a group.

```plaintext
GET /groups/:id/integrations/webex-teams
```

## YouTrack

### Set up YouTrack

Set up the YouTrack integration for a group.

```plaintext
PUT /groups/:id/integrations/youtrack
```

Parameters:

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `issues_url` | string | yes | URL of the issue. |
| `project_url` | string | yes | URL of the project. |
| `use_inherited_settings` | boolean | no | Indicates whether or not to inherit default settings. Defaults to `false`. |

### Disable YouTrack

Disable the YouTrack integration for a group. Integration settings are reset.

```plaintext
DELETE /groups/:id/integrations/youtrack
```

### Get YouTrack settings

Get the YouTrack integration settings for a group.

```plaintext
GET /groups/:id/integrations/youtrack
```
