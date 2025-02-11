---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Log system
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab has an advanced log system where everything is logged, so you can analyze your instance using various system log
files. The log system is similar to [audit events](../audit_event_reports.md).

System log files are typically plain text in a standard log file format.
This guide talks about how to read and use these system log files.

Read more about the log system and using the logs:

- [Customize logging on Linux package installations](https://docs.gitlab.com/omnibus/settings/logs.html)
  including adjusting log retention, log forwarding,
  switching logs from JSON to plain text logging, and more.
- [How to parse and analyze JSON logs](../logs/log_parsing.md).

## Log Levels

Each log message has an assigned log level that indicates its importance and verbosity.
Each logger has an assigned minimum log level.
A logger emits a log message only if its log level is equal to or above the minimum log level.

The following log levels are supported:

| Level | Name      |
|:------|:----------|
| 0     | `DEBUG`   |
| 1     | `INFO`    |
| 2     | `WARN`    |
| 3     | `ERROR`   |
| 4     | `FATAL`   |
| 5     | `UNKNOWN` |

GitLab loggers emit all log messages because they are set to `DEBUG` by default.

### Override default log level

You can override the minimum log level for GitLab loggers using the `GITLAB_LOG_LEVEL` environment variable.
Valid values are either a value of `0` to `5`, or the name of the log level.

Example:

```shell
GITLAB_LOG_LEVEL=info
```

For some services, other log levels are in place that are not affected by this setting.
Some of these services have their own environment variables to override the log level. For example:

| Service              | Log level | Environment variable |
|:---------------------|:----------|:---------------------|
| GitLab Cleanup       | `INFO`    | `DEBUG`              |
| GitLab Doctor        | `INFO`    | `VERBOSE`            |
| GitLab Export        | `INFO`    | `EXPORT_DEBUG`       |
| GitLab Import        | `INFO`    | `IMPORT_DEBUG`       |
| GitLab QA Runtime    | `INFO`    | `QA_LOG_LEVEL`       |
| Google APIs          | `INFO`    |                      |
| Rack Timeout         | `ERROR`   |                      |
| Snowplow Tracker     | `FATAL`   |                      |
| gRPC Client (Gitaly) | `WARN`    | `GRPC_LOG_LEVEL`     |
| LLM                  | `INFO`    | `LLM_DEBUG`          |

## Log Rotation

The logs for a given service may be managed and rotated by:

- `logrotate`
- `svlogd` (`runit`'s service logging daemon)
- `logrotate` and `svlogd`
- Or not at all

The following table includes information about what's responsible for managing and rotating logs for
the included services. Logs
[managed by `svlogd`](https://docs.gitlab.com/omnibus/settings/logs.html#runit-logs)
are written to a file called `current`. The `logrotate` service built into GitLab
[manages all logs](https://docs.gitlab.com/omnibus/settings/logs.html#logrotate)
except those captured by `runit`.

| Log type                                        | Managed by logrotate    | Managed by svlogd/runit |
|:------------------------------------------------|:------------------------|:------------------------|
| [Alertmanager logs](#alertmanager-logs)         | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [crond logs](#crond-logs)                       | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [Gitaly](#gitaly-logs)                          | **{check-circle}** Yes  | **{check-circle}** Yes  |
| [GitLab Exporter for Linux package installations](#gitlab-exporter) | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [GitLab Pages logs](#pages-logs)                | **{check-circle}** Yes  | **{check-circle}** Yes  |
| GitLab Rails                                    | **{check-circle}** Yes  | **{dotted-circle}** No  |
| [GitLab Shell logs](#gitlab-shelllog)           | **{check-circle}** Yes  | **{dotted-circle}** No  |
| [Grafana logs](#grafana-logs)                   | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [LogRotate logs](#logrotate-logs)               | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [Mailroom](#mail_room_jsonlog-default)          | **{check-circle}** Yes  | **{check-circle}** Yes  |
| [NGINX](#nginx-logs)                            | **{check-circle}** Yes  | **{check-circle}** Yes  |
| [PgBouncer logs](#pgbouncer-logs)               | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [PostgreSQL logs](#postgresql-logs)             | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [Praefect logs](#praefect-logs)                 | **{dotted-circle}** Yes | **{check-circle}** Yes  |
| [Prometheus logs](#prometheus-logs)             | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [Puma](#puma-logs)                              | **{check-circle}** Yes  | **{check-circle}** Yes  |
| [Redis logs](#redis-logs)                       | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [Registry logs](#registry-logs)                 | **{dotted-circle}** No  | **{check-circle}** Yes  |
| [Workhorse logs](#workhorse-logs)               | **{check-circle}** Yes  | **{check-circle}** Yes  |

## `production_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/production_json.log` on Linux package installations.
- `/home/git/gitlab/log/production_json.log` on self-compiled installations.

It contains a structured log for Rails controller requests received from
GitLab, thanks to [Lograge](https://github.com/roidrage/lograge/).
Requests from the API are logged to a separate file in `api_json.log`.

Each line contains JSON that can be ingested by services like Elasticsearch and Splunk.
Line breaks were added to examples for legibility:

```json
{
  "method":"GET",
  "path":"/gitlab/gitlab-foss/issues/1234",
  "format":"html",
  "controller":"Projects::IssuesController",
  "action":"show",
  "status":200,
  "time":"2017-08-08T20:15:54.821Z",
  "params":[{"key":"param_key","value":"param_value"}],
  "remote_ip":"18.245.0.1",
  "user_id":1,
  "username":"admin",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "redis_read_bytes":1507378,
  "redis_write_bytes":2920,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id":"puma_0"
}
```

This example was a GET request for a specific
issue. Each line also contains performance data, with times in
seconds:

- `duration_s`: Total time to retrieve the request
- `queue_duration_s`: Total time the request was queued inside GitLab Workhorse
- `view_duration_s`: Total time inside the Rails views
- `db_duration_s`: Total time to retrieve data from PostgreSQL
- `cpu_s`: Total time spent on CPU
- `gitaly_duration_s`: Total time by Gitaly calls
- `gitaly_calls`: Total number of calls made to Gitaly
- `redis_calls`: Total number of calls made to Redis
- `redis_cross_slot_calls`: Total number of cross-slot calls made to Redis
- `redis_allowed_cross_slot_calls`: Total number of allowed cross-slot calls made to Redis
- `redis_duration_s`: Total time to retrieve data from Redis
- `redis_read_bytes`: Total bytes read from Redis
- `redis_write_bytes`: Total bytes written to Redis
- `redis_<instance>_calls`: Total number of calls made to a Redis instance
- `redis_<instance>_cross_slot_calls`: Total number of cross-slot calls made to a Redis instance
- `redis_<instance>_allowed_cross_slot_calls`: Total number of allowed cross-slot calls made to a Redis instance
- `redis_<instance>_duration_s`: Total time to retrieve data from a Redis instance
- `redis_<instance>_read_bytes`: Total bytes read from a Redis instance
- `redis_<instance>_write_bytes`: Total bytes written to a Redis instance
- `pid`: The worker's Linux process ID (changes when workers restart)
- `worker_id`: The worker's logical ID (does not change when workers restart)

User clone and fetch activity using HTTP transport appears in the log as `action: git_upload_pack`.

In addition, the log contains the originating IP address,
(`remote_ip`), the user's ID (`user_id`), and username (`username`).

Some endpoints (such as `/search`) may make requests to Elasticsearch if using
[advanced search](../../user/search/advanced_search.md). These
additionally log `elasticsearch_calls` and `elasticsearch_call_duration_s`,
which correspond to:

- `elasticsearch_calls`: Total number of calls to Elasticsearch
- `elasticsearch_duration_s`: Total time taken by Elasticsearch calls
- `elasticsearch_timed_out_count`: Total number of calls to Elasticsearch that
  timed out and therefore returned partial results

ActionCable connection and subscription events are also logged to this file and they follow the
previous format. The `method`, `path`, and `format` fields are not applicable, and are always empty.
The ActionCable connection or channel class is used as the `controller`.

```json
{
  "method":null,
  "path":null,
  "format":null,
  "controller":"IssuesChannel",
  "action":"subscribe",
  "status":200,
  "time":"2020-05-14T19:46:22.008Z",
  "params":[{"key":"project_path","value":"gitlab/gitlab-foss"},{"key":"iid","value":"1"}],
  "remote_ip":"127.0.0.1",
  "user_id":1,
  "username":"admin",
  "ua":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0",
  "correlation_id":"jSOIEynHCUa",
  "duration_s":0.32566
}
```

NOTE:
If an error occurs, an
`exception` field is included with `class`, `message`, and
`backtrace`. Previous versions included an `error` field instead of
`exception.class` and `exception.message`. For example:

```json
{
  "method": "GET",
  "path": "/admin",
  "format": "html",
  "controller": "Admin::DashboardController",
  "action": "index",
  "status": 500,
  "time": "2019-11-14T13:12:46.156Z",
  "params": [],
  "remote_ip": "127.0.0.1",
  "user_id": 1,
  "username": "root",
  "ua": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:70.0) Gecko/20100101 Firefox/70.0",
  "queue_duration": 274.35,
  "correlation_id": "KjDVUhNvvV3",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id": "puma_0",
  "exception.class": "NameError",
  "exception.message": "undefined local variable or method `adsf' for #<Admin::DashboardController:0x00007ff3c9648588>",
  "exception.backtrace": [
    "app/controllers/admin/dashboard_controller.rb:11:in `index'",
    "ee/app/controllers/ee/admin/dashboard_controller.rb:14:in `index'",
    "ee/lib/gitlab/ip_address_state.rb:10:in `with'",
    "ee/app/controllers/ee/application_controller.rb:43:in `set_current_ip_address'",
    "lib/gitlab/session.rb:11:in `with_session'",
    "app/controllers/application_controller.rb:450:in `set_session_storage'",
    "app/controllers/application_controller.rb:444:in `set_locale'",
    "ee/lib/gitlab/jira/middleware.rb:19:in `call'"
  ]
}
```

## `production.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/production.log` on Linux package installations.
- `/home/git/gitlab/log/production.log` on self-compiled installations.

It contains information about all performed requests. You can see the
URL and type of request, IP address, and what parts of code were
involved to service this particular request. Also, you can see all SQL
requests performed, and how much time each took. This task is
more useful for GitLab contributors and developers. Use part of this log
file when you're reporting bugs. For example:

```plaintext
Started GET "/gitlabhq/yaml_db/tree/master" for 168.111.56.1 at 2015-02-12 19:34:53 +0200
Processing by Projects::TreeController#show as HTML
  Parameters: {"project_id"=>"gitlabhq/yaml_db", "id"=>"master"}

  ... [CUT OUT]

  Namespaces"."created_at" DESC, "namespaces"."id" DESC LIMIT 1 [["id", 26]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members"."type" IN ('ProjectMember') AND "members"."source_id" = $1 AND "members"."source_type" = $2 AND "members"."user_id" = 1  ORDER BY "members"."created_at" DESC, "members"."id" DESC LIMIT 1  [["source_id", 18], ["source_type", "Project"]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members".
  (1.4ms) SELECT COUNT(*) FROM "merge_requests"  WHERE "merge_requests"."target_project_id" = $1 AND ("merge_requests"."state" IN ('opened','reopened')) [["target_project_id", 18]]
  Rendered layouts/nav/_project.html.haml (28.0ms)
  Rendered layouts/_collapse_button.html.haml (0.2ms)
  Rendered layouts/_flash.html.haml (0.1ms)
  Rendered layouts/_page.html.haml (32.9ms)
Completed 200 OK in 166ms (Views: 117.4ms | ActiveRecord: 27.2ms)
```

In this example, the server processed an HTTP request with URL
`/gitlabhq/yaml_db/tree/master` from IP `168.111.56.1` at `2015-02-12 19:34:53 +0200`.
The request was processed by `Projects::TreeController`.

## `api_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/api_json.log` on Linux package installations.
- `/home/git/gitlab/log/api_json.log` on self-compiled installations.

It helps you see requests made directly to the API. For example:

```json
{
  "time":"2018-10-29T12:49:42.123Z",
  "severity":"INFO",
  "duration":709.08,
  "db":14.59,
  "view":694.49,
  "status":200,
  "method":"GET",
  "path":"/api/v4/projects",
  "params":[{"key":"action","value":"git-upload-pack"},{"key":"changes","value":"_any"},{"key":"key_id","value":"secret"},{"key":"secret_token","value":"[FILTERED]"}],
  "host":"localhost",
  "remote_ip":"::1",
  "ua":"Ruby",
  "route":"/api/:version/projects",
  "user_id":1,
  "username":"root",
  "queue_duration":100.31,
  "gitaly_calls":30,
  "gitaly_duration":5.36,
  "pid": 81836,
  "worker_id": "puma_0",
  ...
}
```

This entry shows an internal endpoint accessed to check whether an
associated SSH key can download the project in question by using a `git fetch` or
`git clone`. In this example, we see:

- `duration`: Total time in milliseconds to retrieve the request
- `queue_duration`: Total time in milliseconds the request was queued inside GitLab Workhorse
- `method`: The HTTP method used to make the request
- `path`: The relative path of the query
- `params`: Key-value pairs passed in a query string or HTTP body (sensitive parameters, such as passwords and tokens, are filtered out)
- `ua`: The User-Agent of the requester

NOTE:
As of [`Grape Logging`](https://github.com/aserafin/grape_logging) v1.8.4,
the `view_duration_s` is calculated by [`duration_s - db_duration_s`](https://github.com/aserafin/grape_logging/blob/v1.8.4/lib/grape_logging/middleware/request_logger.rb#L117-L119).
Therefore, `view_duration_s` can be affected by multiple different factors, like read-write
process on Redis or external HTTP, not only the serialization process.

## `application.log` (deprecated)

> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111046) in GitLab 15.10.

This file is located at:

- `/var/log/gitlab/gitlab-rails/application.log` on Linux package installations.
- `/home/git/gitlab/log/application.log` on self-compiled installations.

It contains a less structured version of the logs in
[`application_json.log`](#application_jsonlog), like this example:

```plaintext
October 06, 2014 11:56: User "Administrator" (admin@example.com) was created
October 06, 2014 11:56: Documentcloud created a new project "Documentcloud / Underscore"
October 06, 2014 11:56: Gitlab Org created a new project "Gitlab Org / Gitlab Ce"
October 07, 2014 11:25: User "Claudie Hodkiewicz" (nasir_stehr@olson.co.uk)  was removed
October 07, 2014 11:25: Project "project133" was removed
```

## `application_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/application_json.log` on Linux package installations.
- `/home/git/gitlab/log/application_json.log` on self-compiled installations.

It helps you discover events happening in your instance such as user creation
and project deletion. For example:

```json
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"3823a1550b64417f9c9ed8ee0f48087e",
  "message":"User \"Administrator\" (admin@example.com) was created"
}
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"78e3df10c9a18745243d524540bd5be4",
  "message":"Project \"project133\" was removed"
}
```

## `integrations_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/integrations_json.log` on Linux package installations.
- `/home/git/gitlab/log/integrations_json.log` on self-compiled installations.

It contains information about [integration](../../user/project/integrations/_index.md)
activities, such as Jira, Asana, and irker services. It uses JSON format,
like this example:

```json
{
  "severity":"ERROR",
  "time":"2018-09-06T14:56:20.439Z",
  "service_class":"Integrations::Jira",
  "project_id":8,
  "project_path":"h5bp/html5-boilerplate",
  "message":"Error sending message",
  "client_url":"http://jira.gitlab.com:8080",
  "error":"execution expired"
}
{
  "severity":"INFO",
  "time":"2018-09-06T17:15:16.365Z",
  "service_class":"Integrations::Jira",
  "project_id":3,
  "project_path":"namespace2/project2",
  "message":"Successfully posted",
  "client_url":"http://jira.example.com"
}
```

## `kubernetes.log` (deprecated)

> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

This file is located at:

- `/var/log/gitlab/gitlab-rails/kubernetes.log` on Linux package installations.
- `/home/git/gitlab/log/kubernetes.log` on self-compiled installations.

It logs information related to [certificate-based clusters](../../user/project/clusters/_index.md), such as connectivity errors. Each line contains JSON that can be ingested by services like Elasticsearch and Splunk.

## `git_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/git_json.log` on Linux package installations.
- `/home/git/gitlab/log/git_json.log` on self-compiled installations.

GitLab has to interact with Git repositories, but in some rare cases
something can go wrong. If this happens, you need to know exactly what
happened. This log file contains all failed requests from GitLab to Git
repositories. In the majority of cases this file is useful for developers
only. For example:

```json
{
   "severity":"ERROR",
   "time":"2019-07-19T22:16:12.528Z",
   "correlation_id":"FeGxww5Hj64",
   "message":"Command failed [1]: /usr/bin/git --git-dir=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq/.git --work-tree=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq merge --no-ff -mMerge branch 'feature_conflict' into 'feature' source/feature_conflict\n\nerror: failed to push some refs to '/Users/vsizov/gitlab-development-kit/repositories/gitlabhq/gitlab_git.git'"
}
```

## `audit_json.log`

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

NOTE:
GitLab Free tracks a small number of different audit events.
GitLab Premium tracks many more.

This file is located at:

- `/var/log/gitlab/gitlab-rails/audit_json.log` on Linux package installations.
- `/home/git/gitlab/log/audit_json.log` on self-compiled installations.

Changes to group or project settings and memberships (`target_details`)
are logged to this file. For example:

```json
{
  "severity":"INFO",
  "time":"2018-10-17T17:38:22.523Z",
  "author_id":3,
  "entity_id":2,
  "entity_type":"Project",
  "change":"visibility",
  "from":"Private",
  "to":"Public",
  "author_name":"John Doe4",
  "target_id":2,
  "target_type":"Project",
  "target_details":"namespace2/project2"
}
```

## Sidekiq logs

For Linux package installations, some Sidekiq logs are in `/var/log/gitlab/sidekiq/current`
and as follows.

### `sidekiq.log`

> - The default log format for Helm chart installations [changed from `text` to `json`](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3169) in GitLab 16.0 and later.

This file is located at:

- `/var/log/gitlab/sidekiq/current` on Linux package installations.
- `/home/git/gitlab/log/sidekiq.log` on self-compiled installations.

GitLab uses background jobs for processing tasks which can take a long
time. All information about processing these jobs are written to this
file. For example:

```json
{
  "severity":"INFO",
  "time":"2018-04-03T22:57:22.071Z",
  "queue":"cronjob:update_all_mirrors",
  "args":[],
  "class":"UpdateAllMirrorsWorker",
  "retry":false,
  "queue_namespace":"cronjob",
  "jid":"06aeaa3b0aadacf9981f368e",
  "created_at":"2018-04-03T22:57:21.930Z",
  "enqueued_at":"2018-04-03T22:57:21.931Z",
  "pid":10077,
  "worker_id":"sidekiq_0",
  "message":"UpdateAllMirrorsWorker JID-06aeaa3b0aadacf9981f368e: done: 0.139 sec",
  "job_status":"done",
  "duration":0.139,
  "completed_at":"2018-04-03T22:57:22.071Z",
  "db_duration":0.05,
  "db_duration_s":0.0005,
  "gitaly_duration":0,
  "gitaly_calls":0
}
```

Instead of JSON logs, you can opt to generate text logs for Sidekiq. For example:

```plaintext
2023-05-16T16:08:55.272Z pid=82525 tid=23rl INFO: Initializing websocket
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Booted Rails 6.1.7.2 application in production environment
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Running in ruby 3.0.5p211 (2022-11-24 revision ba5cf0f7c5) [arm64-darwin22]
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: See LICENSE and the LGPL-3.0 for licensing details.
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org
2023-05-16T16:08:55.286Z pid=82525 tid=7p4t INFO: Cleaning working queues
2023-05-16T16:09:06.043Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: start
2023-05-16T16:09:06.050Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: arguments: []
2023-05-16T16:09:06.065Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: start
2023-05-16T16:09:06.066Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: arguments: []
```

For Linux package installations, add the configuration option:

```ruby
sidekiq['log_format'] = 'text'
```

For self-compiled installations, edit the `gitlab.yml` and set the Sidekiq
`log_format` configuration option:

```yaml
  ## Sidekiq
  sidekiq:
    log_format: text
```

### `sidekiq_client.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/sidekiq_client.log` on Linux package installations.
- `/home/git/gitlab/log/sidekiq_client.log` on self-compiled installations.

This file contains logging information about jobs before Sidekiq starts
processing them, such as before being enqueued.

This log file follows the same structure as
[`sidekiq.log`](#sidekiqlog), so it is structured as JSON if
you've configured this for Sidekiq as mentioned above.

## `gitlab-shell.log`

GitLab Shell is used by GitLab for executing Git commands and provide SSH
access to Git repositories.

Information containing `git-{upload-pack,receive-pack}` requests is at
`/var/log/gitlab/gitlab-shell/gitlab-shell.log`. Information about hooks to
GitLab Shell from Gitaly is at `/var/log/gitlab/gitaly/current`.

Example log entries for `/var/log/gitlab/gitlab-shell/gitlab-shell.log`:

```json
{
  "duration_ms": 74.104,
  "level": "info",
  "method": "POST",
  "msg": "Finished HTTP request",
  "time": "2020-04-17T20:28:46Z",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed"
}
{
  "command": "git-upload-pack",
  "git_protocol": "",
  "gl_project_path": "root/example",
  "gl_repository": "project-1",
  "level": "info",
  "msg": "executing git command",
  "time": "2020-04-17T20:28:46Z",
  "user_id": "user-1",
  "username": "root"
}
```

Example log entries for `/var/log/gitlab/gitaly/current`:

```json
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed",
  "duration": 0.058012959,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/pre_receive",
  "duration": 0.031022552,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
```

## Gitaly logs

This file is in `/var/log/gitlab/gitaly/current` and is produced by [runit](https://smarden.org/runit/).
`runit` is packaged with the Linux package and a brief explanation of its purpose
is available [in the Linux package documentation](https://docs.gitlab.com/omnibus/architecture/#runit).
[Log files are rotated](https://smarden.org/runit/svlogd.8), renamed in
Unix timestamp format, and `gzip`-compressed (like `@1584057562.s`).

### `grpc.log`

This file is at `/var/log/gitlab/gitlab-rails/grpc.log` for Linux
package installations. Native [gRPC](https://grpc.io/) logging used by Gitaly.

### `gitaly_hooks.log`

This file is at `/var/log/gitlab/gitaly/gitaly_hooks.log` and is
produced by `gitaly-hooks` command. It also contains records about
failures received during processing of the responses from GitLab API.

## Puma logs

### `puma_stdout.log`

This file is located at:

- `/var/log/gitlab/puma/puma_stdout.log` on Linux package installations.
- `/home/git/gitlab/log/puma_stdout.log` on self-compiled installations.

### `puma_stderr.log`

This file is located at:

- `/var/log/gitlab/puma/puma_stderr.log` on Linux package installations.
- `/home/git/gitlab/log/puma_stderr.log` on self-compiled installations.

## `repocheck.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/repocheck.log` on Linux package installations.
- `/home/git/gitlab/log/repocheck.log` on self-compiled installations.

It logs information whenever a [repository check is run](../repository_checks.md)
on a project.

## `importer.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/importer.log` on Linux package installations.
- `/home/git/gitlab/log/importer.log` on self-compiled installations.

This file logs the progress of [project imports and migrations](../../user/project/import/_index.md).

## `exporter.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/exporter.log` on Linux package installations.
- `/home/git/gitlab/log/exporter.log` on self-compiled installations.

It logs the progress of the export process.

## `features_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/features_json.log` on Linux package installations.
- `/home/git/gitlab/log/features_json.log` on self-compiled installations.

The modification events from [Feature flags in development of GitLab](../../development/feature_flags/_index.md)
are recorded in this file. For example:

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.108Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.129Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"false"}
{"severity":"INFO","time":"2020-11-24T02:31:29.177Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.183Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.188Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_time","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.193Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_time"}
{"severity":"INFO","time":"2020-11-24T02:31:29.198Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_actors","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.203Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_actors"}
{"severity":"INFO","time":"2020-11-24T02:31:29.329Z","correlation_id":null,"key":"cd_auto_rollback","action":"remove"}
```

## `ci_resource_groups_json.log`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384180) in GitLab 15.9.

This file is located at:

- `/var/log/gitlab/gitlab-rails/ci_resource_group_json.log` on Linux package installations.
- `/home/git/gitlab/log/ci_resource_group_json.log` on self-compiled installations.

It contains information about [resource group](../../ci/resource_groups/_index.md) acquisition. For example:

```json
{"severity":"INFO","time":"2023-02-10T23:02:06.095Z","correlation_id":"01GRYS10C2DZQ9J1G12ZVAD4YD","resource_group_id":1,"processable_id":288,"message":"attempted to assign resource to processable","success":true}
{"severity":"INFO","time":"2023-02-10T23:02:08.945Z","correlation_id":"01GRYS138MYEG32C0QEWMC4BDM","resource_group_id":1,"processable_id":288,"message":"attempted to release resource from processable","success":true}
```

The examples show the `resource_group_id`, `processable_id`, `message`, and `success` fields for each entry.

## `auth.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/auth.log` on Linux package installations.
- `/home/git/gitlab/log/auth.log` on self-compiled installations.

This log records:

- Requests over the [Rate Limit](../settings/rate_limits_on_raw_endpoints.md) on raw endpoints.
- [Protected paths](../settings/protected_paths.md) abusive requests.
- User ID and username, if available.

## `auth_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/auth_json.log` on Linux package installations.
- `/home/git/gitlab/log/auth_json.log` on self-compiled installations.

This file contains the JSON version of the logs in `auth.log`, for example:

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"
}
```

## `graphql_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/graphql_json.log` on Linux package installations.
- `/home/git/gitlab/log/graphql_json.log` on self-compiled installations.

GraphQL queries are recorded in the file. For example:

```json
{"query_string":"query IntrospectionQuery{__schema {queryType { name },mutationType { name }}}...(etc)","variables":{"a":1,"b":2},"complexity":181,"depth":1,"duration_s":7}
```

## `clickhouse.log`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133371) in GitLab 16.5.

The `clickhouse.log` file logs information related to the
[ClickHouse database client](../../integration/clickhouse.md) in GitLab.

## `migrations.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/migrations.log` on Linux package installations.
- `/home/git/gitlab/log/migrations.log` on self-compiled installations.

This file logs the progress of [database migrations](../raketasks/maintenance.md#display-status-of-database-migrations).

## `mail_room_json.log` (default)

This file is located at:

- `/var/log/gitlab/mailroom/current` on Linux package installations.
- `/home/git/gitlab/log/mail_room_json.log` on self-compiled installations.

This structured log file records internal activity in the `mail_room` gem.
Its name and path are configurable, so the name and path may not match the above.

## `web_hooks.log`

> - Introduced in GitLab 16.3.

This file is located at:

- `/var/log/gitlab/gitlab-rails/web_hooks.log` on Linux package installations.
- `/home/git/gitlab/log/web_hooks.log` on self-compiled installations.

The back-off, disablement, and re-enablement events for Webhook are recorded in this file. For example:

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"backoff","disabled_until":"2020-11-24T04:30:59.860Z","backoff_count":2,"recent_failures":2}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"disable","disabled_until":null,"backoff_count":5,"recent_failures":100}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"enable","disabled_until":null,"backoff_count":0,"recent_failures":0}
```

## Reconfigure logs

Reconfigure log files are in `/var/log/gitlab/reconfigure` for Linux package installations. Self-compiled installations
don't have reconfigure logs. A reconfigure log is populated whenever `gitlab-ctl reconfigure` is run manually or as part
of an upgrade.

Reconfigure logs files are named according to the UNIX timestamp of when the reconfigure
was initiated, such as `1509705644.log`

## `sidekiq_exporter.log` and `web_exporter.log`

If Prometheus metrics and the Sidekiq Exporter are both enabled, Sidekiq
starts a Web server and listens to the defined port (default:
`8082`). By default, Sidekiq Exporter access logs are disabled but can
be enabled:

- Use the `sidekiq['exporter_log_enabled'] = true` option in `/etc/gitlab/gitlab.rb` on Linux package installations.
- Use the `sidekiq_exporter.log_enabled` option in `gitlab.yml` on self-compiled installations.

When enabled, depending on your installation method, this file is located at:

- `/var/log/gitlab/gitlab-rails/sidekiq_exporter.log` on Linux package installations.
- `/home/git/gitlab/log/sidekiq_exporter.log` on self-compiled installations.

If Prometheus metrics and the Web Exporter are both enabled, Puma
starts a Web server and listens to the defined port (default: `8083`), and access logs
are generated in a location based on your installation method:

- `/var/log/gitlab/gitlab-rails/web_exporter.log` on Linux package installations.
- `/home/git/gitlab/log/web_exporter.log` on self-compiled installations.

## `database_load_balancing.log`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Contains details of GitLab [Database Load Balancing](../postgresql/database_load_balancing.md).
This file is located at:

- `/var/log/gitlab/gitlab-rails/database_load_balancing.log` on Linux package installations.
- `/home/git/gitlab/log/database_load_balancing.log` on self-compiled installations.

## `zoekt.log`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110980) in GitLab 15.9.

This file logs information related to [exact code search](../../user/search/exact_code_search.md).
This file is located at:

- `/var/log/gitlab/gitlab-rails/zoekt.log` on Linux package installations.
- `/home/git/gitlab/log/zoekt.log` on self-compiled installations.

## `elasticsearch.log`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This file logs information related to the Elasticsearch Integration, including
errors during indexing or searching Elasticsearch. This file is located at:

- `/var/log/gitlab/gitlab-rails/elasticsearch.log` on Linux package installations.
- `/home/git/gitlab/log/elasticsearch.log` on self-compiled installations.

Each line contains JSON that can be ingested by services like Elasticsearch and Splunk.
Line breaks have been added to the following example line for clarity:

```json
{
  "severity":"DEBUG",
  "time":"2019-10-17T06:23:13.227Z",
  "correlation_id":null,
  "message":"redacted_search_result",
  "class_name":"Milestone",
  "id":2,
  "ability":"read_milestone",
  "current_user_id":2,
  "query":"project"
}
```

## `exceptions_json.log`

This file logs the information about exceptions being tracked by
`Gitlab::ErrorTracking`, which provides a standard and consistent way of
[processing rescued exceptions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/logging.md#exception-handling).
This file is located at:

- `/var/log/gitlab/gitlab-rails/exceptions_json.log` on Linux package installations.
- `/home/git/gitlab/log/exceptions_json.log` on self-compiled installations.

Each line contains JSON that can be ingested by Elasticsearch. For example:

```json
{
  "severity": "ERROR",
  "time": "2019-12-17T11:49:29.485Z",
  "correlation_id": "AbDVUrrTvM1",
  "extra.project_id": 55,
  "extra.relation_key": "milestones",
  "extra.relation_index": 1,
  "exception.class": "NoMethodError",
  "exception.message": "undefined method `strong_memoize' for #<Gitlab::ImportExport::RelationFactory:0x00007fb5d917c4b0>",
  "exception.backtrace": [
    "lib/gitlab/import_export/relation_factory.rb:329:in `unique_relation?'",
    "lib/gitlab/import_export/relation_factory.rb:345:in `find_or_create_object!'"
  ]
}
```

## `service_measurement.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/service_measurement.log` on Linux package installations.
- `/home/git/gitlab/log/service_measurement.log` on self-compiled installations.

It contains only a single structured log with measurements for each service execution.
It contains measurements such as the number of SQL calls, `execution_time`, `gc_stats`, and `memory usage`.

For example:

```json
{ "severity":"INFO", "time":"2020-04-22T16:04:50.691Z","correlation_id":"04f1366e-57a1-45b8-88c1-b00b23dc3616","class":"Projects::ImportExport::ExportService","current_user":"John Doe","project_full_path":"group1/test-export","file_path":"/path/to/archive","gc_stats":{"count":{"before":127,"after":127,"diff":0},"heap_allocated_pages":{"before":10369,"after":10369,"diff":0},"heap_sorted_length":{"before":10369,"after":10369,"diff":0},"heap_allocatable_pages":{"before":0,"after":0,"diff":0},"heap_available_slots":{"before":4226409,"after":4226409,"diff":0},"heap_live_slots":{"before":2542709,"after":2641420,"diff":98711},"heap_free_slots":{"before":1683700,"after":1584989,"diff":-98711},"heap_final_slots":{"before":0,"after":0,"diff":0},"heap_marked_slots":{"before":2542704,"after":2542704,"diff":0},"heap_eden_pages":{"before":10369,"after":10369,"diff":0},"heap_tomb_pages":{"before":0,"after":0,"diff":0},"total_allocated_pages":{"before":10369,"after":10369,"diff":0},"total_freed_pages":{"before":0,"after":0,"diff":0},"total_allocated_objects":{"before":24896308,"after":24995019,"diff":98711},"total_freed_objects":{"before":22353599,"after":22353599,"diff":0},"malloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"malloc_increase_bytes_limit":{"before":25804104,"after":25804104,"diff":0},"minor_gc_count":{"before":94,"after":94,"diff":0},"major_gc_count":{"before":33,"after":33,"diff":0},"remembered_wb_unprotected_objects":{"before":34284,"after":34284,"diff":0},"remembered_wb_unprotected_objects_limit":{"before":68568,"after":68568,"diff":0},"old_objects":{"before":2404725,"after":2404725,"diff":0},"old_objects_limit":{"before":4809450,"after":4809450,"diff":0},"oldmalloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"oldmalloc_increase_bytes_limit":{"before":68537556,"after":68537556,"diff":0}},"time_to_finish":0.12298400001600385,"number_of_sql_calls":70,"memory_usage":"0.0 MiB","label":"process_48616"}
```

## `geo.log`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Geo stores structured log messages in a `geo.log` file. For Linux package installations,
this file is at `/var/log/gitlab/gitlab-rails/geo.log`.

For Helm chart installations, it's stored in the Sidekiq pod, at `/var/log/gitlab/geo.log`.
It can be read by either directly accessing the file, or by using `kubectl` to fetch the Sidekiq logs, and subsequently filtering the results by `"subcomponent"=="geo"`. The example below uses `jq` to grab only Geo logs:

```shell
kubectl logs -l app=sidekiq --max-log-requests=50 | jq 'select(."subcomponent"=="geo")'
```

This file contains information about when Geo attempts to sync repositories
and files. Each line in the file contains a separate JSON entry that can be
ingested into (for example, Elasticsearch or Splunk).

For example:

```json
{"severity":"INFO","time":"2017-08-06T05:40:16.104Z","message":"Repository update","project_id":1,"source":"repository","resync_repository":true,"resync_wiki":true,"class":"Gitlab::Geo::LogCursor::Daemon","cursor_delay_s":0.038}
```

This message shows that Geo detected that a repository update was needed for project `1`.

## `update_mirror_service_json.log`

This file is located at:

- `/var/log/gitlab/gitlab-rails/update_mirror_service_json.log` on Linux package installations.
- `/home/git/gitlab/log/update_mirror_service_json.log` on self-compiled installations.

This file contains information about LFS errors that occurred during project mirroring.
While we work to move other project mirroring errors into this log, the [general log](#productionlog)
can be used.

```json
{
   "severity":"ERROR",
   "time":"2020-07-28T23:29:29.473Z",
   "correlation_id":"5HgIkCJsO53",
   "user_id":"x",
   "project_id":"x",
   "import_url":"https://mirror-source/group/project.git",
   "error_message":"The LFS objects download list couldn't be imported. Error: Unauthorized"
}
```

## `llm.log`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506) in GitLab 16.0.

The `llm.log` file logs information related to
[AI features](../../user/ai_features.md). Logging includes information about AI events.

### LLM input and output logging

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13401) in GitLab 17.2 [with a flag](../feature_flags.md) named `expanded_ai_logging`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

LLM prompt input and response output can be logged by enabling the `expanded_ai_logging` feature flag.
This flag is disabled by default and can only be enabled:

- For GitLab.com, when you provide consent through a GitLab [Support Ticket](https://about.gitlab.com/support/portal/).
- For GitLab Self-Managed, when you enable this feature flag.

By default, the log does not contain LLM prompt input and response output to support [data retention policies](../../user/gitlab_duo/data_usage.md#data-retention) of AI feature data.

The log file is located at:

- `/var/log/gitlab/gitlab-rails/llm.log` on Linux package installations.
- `/home/git/gitlab/log/llm.log` on self-compiled installations.

## `epic_work_item_sync.log`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506) in GitLab 16.9.

The `epic_work_item_sync.log` file logs information related to syncing and migrating epics as work items.

This file is located at:

- `/var/log/gitlab/gitlab-rails/epic_work_item_sync.log` on Linux package installations.
- `/home/git/gitlab/log/epic_work_item_sync.log` on self-compiled installations.

## `secret_push_protection.log`

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137812) in GitLab 16.7.

The `secret_push_protection.log` file logs information related to [Secret Push Protection](../../user/application_security/secret_detection/secret_push_protection/_index.md) feature.

This file is located at:

- `/var/log/gitlab/gitlab-rails/secret_push_protection.log` on Linux package installations.
- `/home/git/gitlab/log/secret_push_protection.log` on self-compiled installations.

## Registry logs

For Linux package installations, container registry logs are in `/var/log/gitlab/registry/current`.

## NGINX logs

For Linux package installations, NGINX logs are in:

- `/var/log/gitlab/nginx/gitlab_access.log`: A log of requests made to GitLab
- `/var/log/gitlab/nginx/gitlab_error.log`: A log of NGINX errors for GitLab
- `/var/log/gitlab/nginx/gitlab_pages_access.log`: A log of requests made to Pages static sites
- `/var/log/gitlab/nginx/gitlab_pages_error.log`: A log of NGINX errors for Pages static sites
- `/var/log/gitlab/nginx/gitlab_registry_access.log`: A log of requests made to the container registry
- `/var/log/gitlab/nginx/gitlab_registry_error.log`: A log of NGINX errors for the container registry
- `/var/log/gitlab/nginx/gitlab_mattermost_access.log`: A log of requests made to Mattermost
- `/var/log/gitlab/nginx/gitlab_mattermost_error.log`: A log of NGINX errors for Mattermost

Below is the default GitLab NGINX access log format:

```plaintext
'$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
```

The `$request` and `$http_referer` are
[filtered](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/nginx/gitlab)
for sensitive query string parameters such as secret tokens.

## Pages logs

For Linux package installations, Pages logs are in `/var/log/gitlab/gitlab-pages/current`.

For example:

```json
{
  "level": "info",
  "msg": "GitLab Pages Daemon",
  "revision": "52b2899",
  "time": "2020-04-22T17:53:12Z",
  "version": "1.17.0"
}
{
  "level": "info",
  "msg": "URL: https://gitlab.com/gitlab-org/gitlab-pages",
  "time": "2020-04-22T17:53:12Z"
}
{
  "gid": 998,
  "in-place": false,
  "level": "info",
  "msg": "running the daemon as unprivileged user",
  "time": "2020-04-22T17:53:12Z",
  "uid": 998
}
```

## Let's Encrypt logs

For Linux package installations, Let's Encrypt [auto-renew](https://docs.gitlab.com/omnibus/settings/ssl/#renew-the-certificates-automatically) logs are in `/var/log/gitlab/lets-encrypt/`.

## Mattermost logs

For Linux package installations, Mattermost logs are in these locations:

- `/var/log/gitlab/mattermost/mattermost.log`
- `/var/log/gitlab/mattermost/current`

## Workhorse logs

For Linux package installations, Workhorse logs are in `/var/log/gitlab/gitlab-workhorse/current`.

## PgBouncer logs

For Linux package installations, PgBouncer logs are in `/var/log/gitlab/pgbouncer/current`.

## PostgreSQL logs

For Linux package installations, PostgreSQL logs are in `/var/log/gitlab/postgresql/current`.

## Prometheus logs

For Linux package installations, Prometheus logs are in `/var/log/gitlab/prometheus/current`.

## Redis logs

For Linux package installations, Redis logs are in `/var/log/gitlab/redis/current`.

## Alertmanager logs

For Linux package installations, Alertmanager logs are in `/var/log/gitlab/alertmanager/current`.

<!-- vale gitlab_base.Spelling = NO -->

## crond logs

For Linux package installations, crond logs are in `/var/log/gitlab/crond/`.

<!-- vale gitlab_base.Spelling = YES -->

## Grafana logs

For Linux package installations, Grafana logs are in `/var/log/gitlab/grafana/current`.

## LogRotate logs

For Linux package installations, `logrotate` logs are in `/var/log/gitlab/logrotate/current`.

## GitLab Monitor logs

For Linux package installations, GitLab Monitor logs are in `/var/log/gitlab/gitlab-monitor/`.

## GitLab Exporter

For Linux package installations, GitLab Exporter logs are in `/var/log/gitlab/gitlab-exporter/current`.

## GitLab agent server

For Linux package installations, GitLab agent server logs are
in `/var/log/gitlab/gitlab-kas/current`.

## Praefect logs

For Linux package installations, Praefect logs are in `/var/log/gitlab/praefect/`.

GitLab also tracks [Prometheus metrics for Praefect](../gitaly/monitoring.md#monitor-gitaly-cluster).

## Backup log

For Linux package installations, the backup log is located at `/var/log/gitlab/gitlab-rails/backup_json.log`.

For Helm chart installations, the backup log is stored in the Toolbox pod, at `/var/log/gitlab/backup_json.log`.

This log is populated when a [GitLab backup is created](../backup_restore/_index.md). You can use this log to understand how the backup process performed.

## Performance bar stats

This file is located at:

- `/var/log/gitlab/gitlab-rails/performance_bar_json.log` on Linux package installations.
- `/home/git/gitlab/log/performance_bar_json.log` on self-compiled installations.

Performance bar statistics (currently only duration of SQL queries) are recorded
in that file. For example:

```json
{"severity":"INFO","time":"2020-12-04T09:29:44.592Z","correlation_id":"33680b1490ccd35981b03639c406a697","filename":"app/models/ci/pipeline.rb","method_path":"app/models/ci/pipeline.rb:each_with_object","request_id":"rYHomD0VJS4","duration_ms":26.889,"count":2,"query_type": "active-record"}
```

These statistics are logged on .com only, disabled on self-deployments.

## Gathering logs

When [troubleshooting](../troubleshooting/_index.md) issues that aren't localized to one of the
previously listed components, it's helpful to simultaneously gather multiple logs and statistics
from a GitLab instance.

NOTE:
GitLab Support often asks for one of these, and maintains the required tools.

### Briefly tail the main logs

If the bug or error is readily reproducible, save the main GitLab logs
[to a file](../troubleshooting/linux_cheat_sheet.md#files-and-directories) while reproducing the
problem a few times:

```shell
sudo gitlab-ctl tail | tee /tmp/<case-ID-and-keywords>.log
```

Conclude the log gathering with <kbd>Control</kbd> + <kbd>C</kbd>.

### GitLabSOS

If performance degradations or cascading errors occur that can't readily be attributed to one
of the previously listed GitLab components, [GitLabSOS](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/)
can provide a broader perspective of the GitLab instance. For more details and instructions
to run it, read [the GitLabSOS documentation](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/#gitlabsos).

### Fast-stats

[Fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats) is a tool
for creating and comparing performance statistics from GitLab logs.
For more details and instructions to run it, read the
[documentation for fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage).

## Find relevant log entries with a correlation ID

Most requests have a log ID that can be used to [find relevant log entries](tracing_correlation_id.md).
