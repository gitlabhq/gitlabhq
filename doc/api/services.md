# Services

## Asana

Asana - Teamwork without email

### Create/Edit Asana service

Set Asana service for a project.

> This service adds commit messages as comments to Asana tasks. Once enabled, commit messages are checked for Asana task URLs (for example, `https://app.asana.com/0/123456/987654`) or task IDs starting with # (for example, `#987654`). Every task ID found will get the commit comment added to it.  You can also close a task with a message containing: `fix #123456`.  You can find your Api Keys here: https://asana.com/developers/documentation/getting-started/auth#api-key

```
PUT /projects/:id/services/asana
```

Parameters:

- `api_key` (**required**) - User API token. User must have access to task, all comments will be attributed to this user.
- `restrict_to_branch` (optional) - Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches.

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

- `token` (**required**)
- `subdomain` (optional)

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

- `bamboo_url` (**required**) - Bamboo root URL like https://bamboo.example.com
- `build_key` (**required**) - Bamboo build plan key like KEY
- `username` (**required**) - A user with API access, if applicable
- `password` (**required**)

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

## Buildkite

Continuous integration and deployments

### Create/Edit Buildkite service

Set Buildkite service for a project.

```
PUT /projects/:id/services/buildkite
```

Parameters:

- `token` (**required**) - Buildkite project GitLab token
- `project_url` (**required**) - https://buildkite.com/example/project
- `enable_ssl_verification` (optional) - Enable SSL verification

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

- `token` (**required**)
- `subdomain` (optional)
- `room` (optional)

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

- `new_issue_url` (**required**) - New Issue url
- `issues_url` (**required**) - Issue url
- `project_url` (**required**) - Project url
- `description` (optional) - Custom issue tracker
- `title` (optional) - Custom Issue Tracker

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

- `token` (**required**) - Drone CI project specific token
- `drone_url` (**required**) - http://drone.example.com
- `enable_ssl_verification` (optional) - Enable SSL verification

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

- `recipients` (**required**) - Emails separated by whitespace
- `disable_diffs` (optional) - Disable code diffs
- `send_from_committer_email` (optional) - Send from committer

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

- `external_wiki_url` (**required**) - The URL of the external Wiki

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

- `token` (**required**) - Flowdock Git source token

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

- `api_key` (**required**) - Your personal API KEY on gemnasium.com
- `token` (**required**) - The project's slug on gemnasium.com

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

- `token` (**required**) - Room token
- `color` (optional)
- `notify` (optional)
- `room` (optional) - Room name or ID
- `api_version` (optional) - Leave blank for default (v2)
- `server` (optional) - Leave blank for default. https://hipchat.example.com

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

- `recipients` (**required**) - Recipients/channels separated by whitespaces
- `default_irc_uri` (optional) - irc://irc.network.net:6697/
- `server_port` (optional) - 6659
- `server_host` (optional) - localhost
- `colorize_messages` (optional)

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

Jira issue tracker

### Create/Edit JIRA service

Set JIRA service for a project.

> Setting `project_url`, `issues_url` and `new_issue_url` will allow a user to easily navigate to the Jira issue tracker. See the [integration doc](http://docs.gitlab.com/ce/integration/external-issue-tracker.html) for details.  Support for referencing commits and automatic closing of Jira issues directly from GitLab is [available in GitLab EE.](http://docs.gitlab.com/ee/integration/jira.html)

```
PUT /projects/:id/services/jira
```

Parameters:

- `new_issue_url` (**required**) - New Issue url
- `project_url` (**required**) - Project url
- `issues_url` (**required**) - Issue url
- `description` (optional) - Jira issue tracker
- `username` (optional) - Jira username
- `password` (optional) - Jira password

### Delete JIRA service

Delete JIRA service for a project.

```
DELETE /projects/:id/services/jira
```

### Get JIRA service settings

Get JIRA service settings for a project.

```
GET /projects/:id/services/jira
```

## PivotalTracker

Project Management Software (Source Commits Endpoint)

### Create/Edit PivotalTracker service

Set PivotalTracker service for a project.

```
PUT /projects/:id/services/pivotaltracker
```

Parameters:

- `token` (**required**)
- `restrict_to_branch` (optional) - Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches.

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

## Pushover

Pushover makes it easy to get real-time notifications on your Android device, iPhone, iPad, and Desktop.

### Create/Edit Pushover service

Set Pushover service for a project.

```
PUT /projects/:id/services/pushover
```

Parameters:

- `api_key` (**required**) - Your application key
- `user_key` (**required**) - Your user key
- `priority` (**required**)
- `device` (optional) - Leave blank for all active devices
- `sound` (optional)

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

- `new_issue_url` (**required**) - New Issue url
- `project_url` (**required**) - Project url
- `issues_url` (**required**) - Issue url
- `description` (optional) - Redmine issue tracker

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

## Slack

A team communication tool for the 21st century

### Create/Edit Slack service

Set Slack service for a project.

```
PUT /projects/:id/services/slack
```

Parameters:

- `webhook` (**required**) - https://hooks.slack.com/services/...
- `username` (optional) - username
- `channel` (optional) - #channel

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

## JetBrains TeamCity CI

A continuous integration and build server

### Create/Edit JetBrains TeamCity CI service

Set JetBrains TeamCity CI service for a project.

> The build configuration in Teamcity must use the build format number %build.vcs.number% you will also want to configure monitoring of all branches so merge requests build, that setting is in the vsc root advanced settings.

```
PUT /projects/:id/services/teamcity
```

Parameters:

- `teamcity_url` (**required**) - TeamCity root URL like https://teamcity.example.com
- `build_type` (**required**) - Build configuration ID
- `username` (**required**) - A user with permissions to trigger a manual build
- `password` (**required**)

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
