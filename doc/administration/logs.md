---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Log system **(FREE SELF)**

GitLab has an advanced log system where everything is logged, so you
can analyze your instance using various system log files. In addition to
system log files, GitLab Enterprise Edition provides [Audit Events](audit_events.md).

System log files are typically plain text in a standard log file format.
This guide talks about how to read and use these system log files.

Read more about the log system and using the logs:

- [Customize logging on Omnibus GitLab installations](https://docs.gitlab.com/omnibus/settings/logs.html)
including adjusting log retention, log forwarding,
switching logs from JSON to plain text logging, and more.
- [How to parse and analyze JSON logs](troubleshooting/log_parsing.md).

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

| Log type                                        | Managed by logrotate   | Managed by svlogd/runit |
|-------------------------------------------------|------------------------|-------------------------|
| [Alertmanager Logs](#alertmanager-logs)         | **{dotted-circle}** No | **{check-circle}** Yes  |
| [Crond Logs](#crond-logs)                       | **{dotted-circle}** No | **{check-circle}** Yes  |
| [Gitaly](#gitaly-logs)                          | **{check-circle}** Yes | **{check-circle}** Yes  |
| [GitLab Exporter for Omnibus](#gitlab-exporter) | **{dotted-circle}** No | **{check-circle}** Yes  |
| [GitLab Pages Logs](#pages-logs)                | **{check-circle}** Yes | **{check-circle}** Yes  |
| GitLab Rails                                    | **{check-circle}** Yes | **{dotted-circle}** No  |
| [GitLab Shell Logs](#gitlab-shelllog)           | **{check-circle}** Yes | **{dotted-circle}** No  |
| [Grafana Logs](#grafana-logs)                   | **{dotted-circle}** No | **{check-circle}** Yes  |
| [LogRotate Logs](#logrotate-logs)               | **{dotted-circle}** No | **{check-circle}** Yes  |
| [Mailroom](#mail_room_jsonlog-default)          | **{check-circle}** Yes | **{check-circle}** Yes  |
| [NGINX](#nginx-logs)                            | **{check-circle}** Yes | **{check-circle}** Yes  |
| [PostgreSQL Logs](#postgresql-logs)             | **{dotted-circle}** No | **{check-circle}** Yes  |
| [Prometheus Logs](#prometheus-logs)             | **{dotted-circle}** No | **{check-circle}** Yes  |
| [Puma](#puma-logs)                              | **{check-circle}** Yes | **{check-circle}** Yes  |
| [Redis Logs](#redis-logs)                       | **{dotted-circle}** No | **{check-circle}** Yes  |
| [Registry Logs](#registry-logs)                 | **{dotted-circle}** No | **{check-circle}** Yes  |
| [Workhorse Logs](#workhorse-logs)               | **{check-circle}** Yes | **{check-circle}** Yes  |

## `production_json.log`

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/production_json.log`
- Installations from source: `/home/git/gitlab/log/production_json.log`

When GitLab is running in an environment other than production,
the corresponding log file is shown here.

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
  "duration_s":20.54
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
- `redis_duration_s`: Total time to retrieve data from Redis
- `redis_read_bytes`: Total bytes read from Redis
- `redis_write_bytes`: Total bytes written to Redis
- `redis_<instance>_calls`: Total number of calls made to a Redis instance
- `redis_<instance>_duration_s`: Total time to retrieve data from a Redis instance
- `redis_<instance>_read_bytes`: Total bytes read from a Redis instance
- `redis_<instance>_write_bytes`: Total bytes written to a Redis instance

User clone and fetch activity using HTTP transport appears in the log as `action: git_upload_pack`.

In addition, the log contains the originating IP address,
(`remote_ip`), the user's ID (`user_id`), and username (`username`).

Some endpoints (such as `/search`) may make requests to Elasticsearch if using
[Advanced Search](../user/search/advanced_search.md). These
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
Starting with GitLab 12.5, if an error occurs, an
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
  "duration_s":20.54
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

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/production.log`
- Installations from source: `/home/git/gitlab/log/production.log`

When GitLab is running in an environment other than production,
the corresponding log file is shown here.

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

> Introduced in GitLab 10.0.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/api_json.log`
- Installations from source: `/home/git/gitlab/log/api_json.log`

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
  "gitaly_duration":5.36
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

## `application.log`

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/application.log`
- Installations from source: `/home/git/gitlab/log/application.log`

It helps you discover events happening in your instance such as user creation
and project removal. For example:

```plaintext
October 06, 2014 11:56: User "Administrator" (admin@example.com) was created
October 06, 2014 11:56: Documentcloud created a new project "Documentcloud / Underscore"
October 06, 2014 11:56: Gitlab Org created a new project "Gitlab Org / Gitlab Ce"
October 07, 2014 11:25: User "Claudie Hodkiewicz" (nasir_stehr@olson.co.uk)  was removed
October 07, 2014 11:25: Project "project133" was removed
```

## `application_json.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22812) in GitLab 12.7.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/application_json.log`
- Installations from source: `/home/git/gitlab/log/application_json.log`

It contains the JSON version of the logs in `application.log`, like this example:

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

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/integrations_json.log`
- Installations from source: `/home/git/gitlab/log/integrations_json.log`

It contains information about [integration](../user/project/integrations/overview.md)
activities, such as Jira, Asana, and Irker services. It uses JSON format,
like this example:

```json
{
  "severity":"ERROR",
  "time":"2018-09-06T14:56:20.439Z",
  "service_class":"Integrations::Jira",
  "project_id":8,
  "project_path":"h5bp/html5-boilerplate",
  "message":"Error sending message",
  "client_url":"http://jira.gitlap.com:8080",
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

## `kubernetes.log`

> Introduced in GitLab 11.6.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/kubernetes.log`
- Installations from source: `/home/git/gitlab/log/kubernetes.log`

It logs information related to the Kubernetes Integration, including errors
during installing cluster applications on your managed Kubernetes
clusters.

Each line contains JSON that can be ingested by services like Elasticsearch and Splunk.
Line breaks have been added to the following example for clarity:

```json
{
  "severity":"ERROR",
  "time":"2018-11-23T15:14:54.652Z",
  "exception":"Kubeclient::HttpError",
  "error_code":401,
  "service":"Clusters::Applications::CheckInstallationProgressService",
  "app_id":14,
  "project_ids":[1],
  "group_ids":[],
  "message":"Unauthorized"
}
{
  "severity":"ERROR",
  "time":"2018-11-23T15:42:11.647Z",
  "exception":"Kubeclient::HttpError",
  "error_code":null,
  "service":"Clusters::Applications::InstallService",
  "app_id":2,
  "project_ids":[19],
  "group_ids":[],
  "message":"SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate)"
}
```

## `git_json.log`

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/git_json.log`
- Installations from source: `/home/git/gitlab/log/git_json.log`

After GitLab version 12.2, this file was renamed from `githost.log` to
`git_json.log` and stored in JSON format.

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

## `audit_json.log` **(FREE)**

NOTE:
GitLab Free tracks a small number of different audit events.
GitLab Premium tracks many more.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/audit_json.log`
- Installations from source: `/home/git/gitlab/log/audit_json.log`

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

## Sidekiq Logs

NOTE:
In Omnibus GitLab `12.10` or earlier, the Sidekiq log is at `/var/log/gitlab/gitlab-rails/sidekiq.log`.

For Omnibus GitLab installations, some Sidekiq logs are in `/var/log/gitlab/sidekiq/current`
and as follows.

### `sidekiq.log`

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/sidekiq/current`
- Installations from source: `/home/git/gitlab/log/sidekiq.log`

GitLab uses background jobs for processing tasks which can take a long
time. All information about processing these jobs are written down to
this file. For example:

```plaintext
2014-06-10T07:55:20Z 2037 TID-tm504 ERROR: /opt/bitnami/apps/discourse/htdocs/vendor/bundle/ruby/1.9.1/gems/redis-3.0.7/lib/redis/client.rb:228:in `read'
2014-06-10T18:18:26Z 14299 TID-55uqo INFO: Booting Sidekiq 3.0.0 with redis options {:url=>"redis://localhost:6379/0", :namespace=>"sidekiq"}
```

Instead of the previous format, you can opt to generate JSON logs for
Sidekiq. For example:

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

For Omnibus GitLab installations, add the configuration option:

```ruby
sidekiq['log_format'] = 'json'
```

For installations from source, edit the `gitlab.yml` and set the Sidekiq
`log_format` configuration option:

```yaml
  ## Sidekiq
  sidekiq:
    log_format: json
```

### `sidekiq_client.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26586) in GitLab 12.9.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/sidekiq_client.log`
- Installations from source: `/home/git/gitlab/log/sidekiq_client.log`

This file contains logging information about jobs before Sidekiq starts
processing them, such as before being enqueued.

This log file follows the same structure as
[`sidekiq.log`](#sidekiqlog), so it is structured as JSON if
you've configured this for Sidekiq as mentioned above.

## `gitlab-shell.log`

GitLab Shell is used by GitLab for executing Git commands and provide SSH
access to Git repositories.

### For GitLab versions 12.10 and up

For GitLab version 12.10 and later, there are two `gitlab-shell.log` files.
Information containing `git-{upload-pack,receive-pack}` requests is at
`/var/log/gitlab/gitlab-shell/gitlab-shell.log`. Information about hooks to
GitLab Shell from Gitaly is at `/var/log/gitlab/gitaly/gitlab-shell.log`.

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

Example log entries for `/var/log/gitlab/gitaly/gitlab-shell.log`:

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

### For GitLab versions 12.5 through 12.9

For GitLab 12.5 to 12.9, depending on your installation method, this
file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitaly/gitlab-shell.log`
- Installation from source: `/home/git/gitaly/gitlab-shell.log`

Example log entries:

```json
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/post_receive",
  "duration": 0.031809164,
  "gitaly_embedded": true,
  "pid": 27056,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T16:24:38+00:00"
}
```

### For GitLab 12.5 and earlier

For GitLab 12.5 and earlier, the file is at `/var/log/gitlab/gitlab-shell/gitlab-shell.log`.

Example log entries:

```plaintext
I, [2015-02-13T06:17:00.671315 #9291]  INFO -- : Adding project root/example.git at </var/opt/gitlab/git-data/repositories/root/dcdcdcdcd.git>.
I, [2015-02-13T06:17:00.679433 #9291]  INFO -- : Moving existing hooks directory and symlinking global hooks directory for /var/opt/gitlab/git-data/repositories/root/example.git.
```

User clone/fetch activity using SSH transport appears in this log as
`executing git command <gitaly-upload-pack...`.

## Gitaly Logs

This file is in `/var/log/gitlab/gitaly/current` and is produced by [runit](http://smarden.org/runit/).
`runit` is packaged with Omnibus GitLab and a brief explanation of its purpose
is available [in the Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/architecture/#runit).
[Log files are rotated](http://smarden.org/runit/svlogd.8.html), renamed in
Unix timestamp format, and `gzip`-compressed (like `@1584057562.s`).

### `grpc.log`

This file is at `/var/log/gitlab/gitlab-rails/grpc.log` for Omnibus GitLab
packages. Native [gRPC](https://grpc.io/) logging used by Gitaly.

### `gitaly_ruby_json.log`

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/2678) in GitLab 13.6.

This file is at `/var/log/gitlab/gitaly/gitaly_ruby_json.log` and is
produced by [`gitaly-ruby`](gitaly/reference.md#gitaly-ruby). It contains an
access log of gRPC calls made by Gitaly to `gitaly-ruby`.

## Puma Logs

### `puma_stdout.log`

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/puma/puma_stdout.log`
- Installations from source: `/home/git/gitlab/log/puma_stdout.log`

### `puma_stderr.log`

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/puma/puma_stderr.log`
- Installations from source: `/home/git/gitlab/log/puma_stderr.log`

## `repocheck.log`

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/repocheck.log`
- Installations from source: `/home/git/gitlab/log/repocheck.log`

It logs information whenever a [repository check is run](repository_checks.md)
on a project.

## `importer.log`

> Introduced in GitLab 11.3.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/importer.log`
- Installations from source: `/home/git/gitlab/log/importer.log`

It logs the progress of the import process.

## `exporter.log`

> Introduced in GitLab 13.1.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/exporter.log`
- Installations from source: `/home/git/gitlab/log/exporter.log`

It logs the progress of the export process.

## `features_json.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/59587) in GitLab 13.7.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/features_json.log`
- Installations from source: `/home/git/gitlab/log/features_json.log`

The modification events from [Feature flags in development of GitLab](../development/feature_flags/index.md)
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

## `auth.log`

> Introduced in GitLab 12.0.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/auth.log`
- Installations from source: `/home/git/gitlab/log/auth.log`

This log records:

- Information whenever [Rack Attack](../security/rack_attack.md) registers an abusive request.
- Requests over the [Rate Limit](../user/admin_area/settings/rate_limits_on_raw_endpoints.md) on raw endpoints.
- [Protected paths](../user/admin_area/settings/protected_paths.md) abusive requests.
- In GitLab versions [12.3](https://gitlab.com/gitlab-org/gitlab/-/issues/29239) and later,
  user ID and username, if available.

## `graphql_json.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/59587) in GitLab 12.0.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/graphql_json.log`
- Installations from source: `/home/git/gitlab/log/graphql_json.log`

GraphQL queries are recorded in the file. For example:

```json
{"query_string":"query IntrospectionQuery{__schema {queryType { name },mutationType { name }}}...(etc)","variables":{"a":1,"b":2},"complexity":181,"depth":1,"duration_s":7}
```

## `migrations.log`

> Introduced in GitLab 12.3.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/migrations.log`
- Installations from source: `/home/git/gitlab/log/migrations.log`

## `mail_room_json.log` (default)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/19186) in GitLab 12.6.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/mailroom/current`
- Installations from source: `/home/git/gitlab/log/mail_room_json.log`

This structured log file records internal activity in the `mail_room` gem.
Its name and path are configurable, so the name and path may not match the above.

## Reconfigure logs

Reconfigure log files are in `/var/log/gitlab/reconfigure` for Omnibus GitLab
packages. Installations from source don't have reconfigure logs. A reconfigure log
is populated whenever `gitlab-ctl reconfigure` is run manually or as part of an upgrade.

Reconfigure logs files are named according to the UNIX timestamp of when the reconfigure
was initiated, such as `1509705644.log`

## `sidekiq_exporter.log` and `web_exporter.log`

If Prometheus metrics and the Sidekiq Exporter are both enabled, Sidekiq
starts a Web server and listen to the defined port (default:
`8082`). By default, Sidekiq Exporter access logs are disabled but can
be enabled based on your installation method:

- Omnibus GitLab: Use the `sidekiq['exporter_log_enabled'] = true`
  option in `/etc/gitlab/gitlab.rb`
- Installations from source: Use the `sidekiq_exporter.log_enabled` option
  in `gitlab.yml`

When enabled, depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/sidekiq_exporter.log`
- Installations from source: `/home/git/gitlab/log/sidekiq_exporter.log`

If Prometheus metrics and the Web Exporter are both enabled, Puma
starts a Web server and listen to the defined port (default: `8083`), and access logs
are generated in a location based on your installation method:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/web_exporter.log`
- Installations from source: `/home/git/gitlab/log/web_exporter.log`

## `database_load_balancing.log` **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/15442) in GitLab 12.3.

Contains details of GitLab [Database Load Balancing](database_load_balancing.md).
Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/database_load_balancing.log`
- Installations from source: `/home/git/gitlab/log/database_load_balancing.log`

## `elasticsearch.log` **(PREMIUM SELF)**

> Introduced in GitLab 12.6.

This file logs information related to the Elasticsearch Integration, including
errors during indexing or searching Elasticsearch. Depending on your installation
method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/elasticsearch.log`
- Installations from source: `/home/git/gitlab/log/elasticsearch.log`

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17819) in GitLab 12.6.

This file logs the information about exceptions being tracked by
`Gitlab::ErrorTracking`, which provides a standard and consistent way of
[processing rescued exceptions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/logging.md#exception-handling).
Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/exceptions_json.log`
- Installations from source: `/home/git/gitlab/log/exceptions_json.log`

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

> Introduced in GitLab 13.0.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/service_measurement.log`
- Installations from source: `/home/git/gitlab/log/service_measurement.log`

It contains only a single structured log with measurements for each service execution.
It contains measurements such as the number of SQL calls, `execution_time`, `gc_stats`, and `memory usage`.

For example:

```json
{ "severity":"INFO", "time":"2020-04-22T16:04:50.691Z","correlation_id":"04f1366e-57a1-45b8-88c1-b00b23dc3616","class":"Projects::ImportExport::ExportService","current_user":"John Doe","project_full_path":"group1/test-export","file_path":"/path/to/archive","gc_stats":{"count":{"before":127,"after":127,"diff":0},"heap_allocated_pages":{"before":10369,"after":10369,"diff":0},"heap_sorted_length":{"before":10369,"after":10369,"diff":0},"heap_allocatable_pages":{"before":0,"after":0,"diff":0},"heap_available_slots":{"before":4226409,"after":4226409,"diff":0},"heap_live_slots":{"before":2542709,"after":2641420,"diff":98711},"heap_free_slots":{"before":1683700,"after":1584989,"diff":-98711},"heap_final_slots":{"before":0,"after":0,"diff":0},"heap_marked_slots":{"before":2542704,"after":2542704,"diff":0},"heap_eden_pages":{"before":10369,"after":10369,"diff":0},"heap_tomb_pages":{"before":0,"after":0,"diff":0},"total_allocated_pages":{"before":10369,"after":10369,"diff":0},"total_freed_pages":{"before":0,"after":0,"diff":0},"total_allocated_objects":{"before":24896308,"after":24995019,"diff":98711},"total_freed_objects":{"before":22353599,"after":22353599,"diff":0},"malloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"malloc_increase_bytes_limit":{"before":25804104,"after":25804104,"diff":0},"minor_gc_count":{"before":94,"after":94,"diff":0},"major_gc_count":{"before":33,"after":33,"diff":0},"remembered_wb_unprotected_objects":{"before":34284,"after":34284,"diff":0},"remembered_wb_unprotected_objects_limit":{"before":68568,"after":68568,"diff":0},"old_objects":{"before":2404725,"after":2404725,"diff":0},"old_objects_limit":{"before":4809450,"after":4809450,"diff":0},"oldmalloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"oldmalloc_increase_bytes_limit":{"before":68537556,"after":68537556,"diff":0}},"time_to_finish":0.12298400001600385,"number_of_sql_calls":70,"memory_usage":"0.0 MiB","label":"process_48616"}
```

## `geo.log` **(PREMIUM SELF)**

> Introduced in 9.5.

Geo stores structured log messages in a `geo.log` file. For Omnibus GitLab
installations, this file is at `/var/log/gitlab/gitlab-rails/geo.log`.

This file contains information about when Geo attempts to sync repositories
and files. Each line in the file contains a separate JSON entry that can be
ingested into (for example, Elasticsearch or Splunk).

For example:

```json
{"severity":"INFO","time":"2017-08-06T05:40:16.104Z","message":"Repository update","project_id":1,"source":"repository","resync_repository":true,"resync_wiki":true,"class":"Gitlab::Geo::LogCursor::Daemon","cursor_delay_s":0.038}
```

This message shows that Geo detected that a repository update was needed for project `1`.

## `update_mirror_service_json.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/commit/7f637e2af7006dc2b1b2649d9affc0b86cfb33c4) in GitLab 11.12.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/update_mirror_service_json.log`
- Installations from source: `/home/git/gitlab/log/update_mirror_service_json.log`

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

## Registry Logs

For Omnibus GitLab installations, Container Registry logs are in `/var/log/gitlab/registry/current`.

## NGINX Logs

For Omnibus GitLab installations, NGINX logs are in:

- `/var/log/gitlab/nginx/gitlab_access.log`: A log of requests made to GitLab
- `/var/log/gitlab/nginx/gitlab_error.log`: A log of NGINX errors for GitLab
- `/var/log/gitlab/nginx/gitlab_pages_access.log`: A log of requests made to Pages static sites
- `/var/log/gitlab/nginx/gitlab_pages_error.log`: A log of NGINX errors for Pages static sites
- `/var/log/gitlab/nginx/gitlab_registry_access.log`: A log of requests made to the Container Registry
- `/var/log/gitlab/nginx/gitlab_registry_error.log`: A log of NGINX errors for the Container Registry
- `/var/log/gitlab/nginx/gitlab_mattermost_access.log`: A log of requests made to Mattermost
- `/var/log/gitlab/nginx/gitlab_mattermost_error.log`: A log of NGINX errors for Mattermost

Below is the default GitLab NGINX access log format:

```plaintext
$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
```

## Pages Logs

For Omnibus GitLab installations, Pages logs are in `/var/log/gitlab/gitlab-pages/current`.

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

## Mattermost Logs

For Omnibus GitLab installations, Mattermost logs are in `/var/log/gitlab/mattermost/mattermost.log`.

## Workhorse Logs

For Omnibus GitLab installations, Workhorse logs are in `/var/log/gitlab/gitlab-workhorse/`.

## PostgreSQL Logs

For Omnibus GitLab installations, PostgreSQL logs are in `/var/log/gitlab/postgresql/`.

## Prometheus Logs

For Omnibus GitLab installations, Prometheus logs are in `/var/log/gitlab/prometheus/`.

## Redis Logs

For Omnibus GitLab installations, Redis logs are in `/var/log/gitlab/redis/`.

## Alertmanager Logs

For Omnibus GitLab installations, Alertmanager logs are in `/var/log/gitlab/alertmanager/`.

<!-- vale gitlab.Spelling = NO -->

## Crond Logs

For Omnibus GitLab installations, crond logs are in `/var/log/gitlab/crond/`.

<!-- vale gitlab.Spelling = YES -->

## Grafana Logs

For Omnibus GitLab installations, Grafana logs are in `/var/log/gitlab/grafana/`.

## LogRotate Logs

For Omnibus GitLab installations, `logrotate` logs are in `/var/log/gitlab/logrotate/`.

## GitLab Monitor Logs

For Omnibus GitLab installations, GitLab Monitor logs are in `/var/log/gitlab/gitlab-monitor/`.

## GitLab Exporter

For Omnibus GitLab installations, GitLab Exporter logs are in `/var/log/gitlab/gitlab-exporter/`.

## GitLab Kubernetes Agent Server

For Omnibus GitLab installations, GitLab Kubernetes Agent Server logs are
in `/var/log/gitlab/gitlab-kas/`.

## Performance bar stats

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/48149) in GitLab 13.7.

Depending on your installation method, this file is located at:

- Omnibus GitLab: `/var/log/gitlab/gitlab-rails/performance_bar_json.log`
- Installations from source: `/home/git/gitlab/log/performance_bar_json.log`

Performance bar statistics (currently only duration of SQL queries) are recorded
in that file. For example:

```json
{"severity":"INFO","time":"2020-12-04T09:29:44.592Z","correlation_id":"33680b1490ccd35981b03639c406a697","filename":"app/models/ci/pipeline.rb","method_path":"app/models/ci/pipeline.rb:each_with_object","request_id":"rYHomD0VJS4","duration_ms":26.889,"count":2,"type": "sql"}
```

These statistics are logged on .com only, disabled on self-deployments.

## Gathering logs

When [troubleshooting](troubleshooting/index.md) issues that aren't localized to one of the
previously listed components, it's helpful to simultaneously gather multiple logs and statistics
from a GitLab instance.

NOTE:
GitLab Support often asks for one of these, and maintains the required tools.

### Briefly tail the main logs

If the bug or error is readily reproducible, save the main GitLab logs
[to a file](troubleshooting/linux_cheat_sheet.md#files-and-directories) while reproducing the
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
