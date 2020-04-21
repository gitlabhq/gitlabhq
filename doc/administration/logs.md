# Log system

GitLab has an advanced log system where everything is logged, so you
can analyze your instance using various system log files. In addition to
system log files, GitLab Enterprise Edition provides Audit Events.
Find more about them [in Audit Events documentation](audit_events.md).

System log files are typically plain text in a standard log file format.
This guide talks about how to read and use these system log files.

## `production_json.log`

This file lives in `/var/log/gitlab/gitlab-rails/production_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/production_json.log` for
installations from source. When GitLab is running in an environment
other than production, the corresponding log file is shown here.

It contains a structured log for Rails controller requests received from
GitLab, thanks to [Lograge](https://github.com/roidrage/lograge/). Note that
requests from the API are logged to a separate file in `api_json.log`.

Each line contains a JSON line that can be ingested by services like Elasticsearch and Splunk.
Line breaks have been added to this example for legibility:

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
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54
}
```

This example was a GET request for a specific
issue. Each line also contains performance data, with times in
milliseconds:

1. `duration_s`: total time taken to retrieve the request
1. `queue_duration_s`: total time that the request was queued inside GitLab Workhorse
1. `view_duration_s`: total time taken inside the Rails views
1. `db_duration_s`: total time to retrieve data from PostgreSQL
1. `redis_duration_s`: total time to retrieve data from Redis
1. `cpu_s`: total time spent on CPU
1. `gitaly_duration_s`: total time taken by Gitaly calls
1. `gitaly_calls`: total number of calls made to Gitaly
1. `redis_calls`: total number of calls made to Redis

User clone and fetch activity using HTTP transport appears in this log as `action: git_upload_pack`.

In addition, the log contains the originating IP address,
(`remote_ip`),the user's ID (`user_id`), and username (`username`).

NOTE: **Note:** Starting with GitLab 12.5, if an error occurs, an
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

This file lives in `/var/log/gitlab/gitlab-rails/production.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/production.log` for
installations from source. (When GitLab is running in an environment
other than production, the corresponding log file is shown here.)

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

This file lives in
`/var/log/gitlab/gitlab-rails/api_json.log` for Omnibus GitLab packages, or in
`/home/git/gitlab/log/api_json.log` for installations from source.

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

This entry shows an access to an internal endpoint to check whether an
associated SSH key can download the project in question via a `git fetch` or
`git clone`. In this example, we see:

1. `duration`: total time in milliseconds taken to retrieve the request
1. `queue_duration`: total time in milliseconds that the request was queued inside GitLab Workhorse
1. `method`: The HTTP method used to make the request
1. `path`: The relative path of the query
1. `params`: Key-value pairs passed in a query string or HTTP body. Sensitive parameters (such as passwords and tokens) are filtered out.
1. `ua`: The User-Agent of the requester

## `application.log`

This file lives in `/var/log/gitlab/gitlab-rails/application.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/application.log` for
installations from source.

It helps you discover events happening in your instance such as user creation,
project removing and so on. For example:

```plaintext
October 06, 2014 11:56: User "Administrator" (admin@example.com) was created
October 06, 2014 11:56: Documentcloud created a new project "Documentcloud / Underscore"
October 06, 2014 11:56: Gitlab Org created a new project "Gitlab Org / Gitlab Ce"
October 07, 2014 11:25: User "Claudie Hodkiewicz" (nasir_stehr@olson.co.uk)  was removed
October 07, 2014 11:25: Project "project133" was removed
```

## `application_json.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/22812) in GitLab 12.7.

This file lives in `/var/log/gitlab/gitlab-rails/application_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/application_json.log` for
installations from source.

It contains the JSON version of the logs in `application.log` like the example below:

``` json
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

This file lives in `/var/log/gitlab/gitlab-rails/integrations_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/integrations_json.log` for
installations from source.

It contains information about [integrations](../user/project/integrations/overview.md) activities such as Jira, Asana, and Irker services. It uses JSON format like the example below:

```json
{
  "severity":"ERROR",
  "time":"2018-09-06T14:56:20.439Z",
  "service_class":"JiraService",
  "project_id":8,
  "project_path":"h5bp/html5-boilerplate",
  "message":"Error sending message",
  "client_url":"http://jira.gitlap.com:8080",
  "error":"execution expired"
}
{
  "severity":"INFO",
  "time":"2018-09-06T17:15:16.365Z",
  "service_class":"JiraService",
  "project_id":3,
  "project_path":"namespace2/project2",
  "message":"Successfully posted",
  "client_url":"http://jira.example.com"
}
```

## `kubernetes.log`

> Introduced in GitLab 11.6.

This file lives in
`/var/log/gitlab/gitlab-rails/kubernetes.log` for Omnibus GitLab
packages or in `/home/git/gitlab/log/kubernetes.log` for
installations from source.

It logs information related to the Kubernetes Integration including errors
during installing cluster applications on your GitLab managed Kubernetes
clusters.

Each line contains a JSON line that can be ingested by services like Elasticsearch and Splunk.
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

This file lives in `/var/log/gitlab/gitlab-rails/git_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/git_json.log` for
installations from source.

NOTE: **Note:**
After 12.2, this file was renamed from `githost.log` to
`git_json.log` and stored in JSON format.

GitLab has to interact with Git repositories, but in some rare cases
something can go wrong, and in this case you will know what exactly
happened. This log file contains all failed requests from GitLab to Git
repositories. In the majority of cases this file will be useful for developers
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

This file lives in `/var/log/gitlab/gitlab-rails/audit_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/audit_json.log` for
installations from source.

Changes to group or project settings are logged to this file. For example:

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

## `sidekiq.log`

This file lives in `/var/log/gitlab/gitlab-rails/sidekiq.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/sidekiq.log` for
installations from source.

GitLab uses background jobs for processing tasks which can take a long
time. All information about processing these jobs are written down to
this file. For example:

```plaintext
2014-06-10T07:55:20Z 2037 TID-tm504 ERROR: /opt/bitnami/apps/discourse/htdocs/vendor/bundle/ruby/1.9.1/gems/redis-3.0.7/lib/redis/client.rb:228:in `read'
2014-06-10T18:18:26Z 14299 TID-55uqo INFO: Booting Sidekiq 3.0.0 with redis options {:url=>"redis://localhost:6379/0", :namespace=>"sidekiq"}
```

Instead of the format above, you can opt to generate JSON logs for
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

For source installations, edit the `gitlab.yml` and set the Sidekiq
`log_format` configuration option:

```yaml
  ## Sidekiq
  sidekiq:
    log_format: json
```

## `sidekiq_client.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26586) in GitLab 12.9.

This file lives in `/var/log/gitlab/gitlab-rails/sidekiq_client.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/sidekiq_client.log` for
installations from source.

This file contains logging information about jobs before they are start
being processed by Sidekiq, for example before being enqueued.

This logfile follows the same structure as
[`sidekiq.log`](#sidekiqlog), so it will be structured as JSON if
you've configured this for Sidekiq as mentioned above.

## `gitlab-shell.log`

GitLab Shell is used by GitLab for executing Git commands and provide SSH access to Git repositories.

### For GitLab versions 12.10 and up

For GitLab version 12.10 and later, there are 2 `gitlab-shell.log` files. Information containing `git-{upload-pack,receive-pack}` requests lives in `/var/log/gitlab/gitlab-shell/gitlab-shell.log`. Information about hooks to GitLab Shell from Gitaly lives in `/var/log/gitlab/gitaly/gitlab-shell.log`.

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

For GitLab 12.5 to 12.9, this file lives in `/var/log/gitlab/gitaly/gitlab-shell.log` for Omnibus GitLab packages or in `/home/git/gitaly/gitlab-shell.log` for installations from source.

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

For GitLab 12.5 and earlier, the file lives in `/var/log/gitlab/gitlab-shell/gitlab-shell.log`.

Example log entries:

```plaintext
I, [2015-02-13T06:17:00.671315 #9291]  INFO -- : Adding project root/example.git at </var/opt/gitlab/git-data/repositories/root/dcdcdcdcd.git>.
I, [2015-02-13T06:17:00.679433 #9291]  INFO -- : Moving existing hooks directory and symlinking global hooks directory for /var/opt/gitlab/git-data/repositories/root/example.git.
```

User clone/fetch activity using SSH transport appears in this log as `executing git command <gitaly-upload-pack...`.

## `current`

This file lives in `/var/log/gitlab/gitaly/current` and is produced by [runit](http://smarden.org/runit/). `runit` is packaged with Omnibus and a brief explanation of its purpose is available [in the omnibus documentation](https://docs.gitlab.com/omnibus/architecture/#runit). [Log files are rotated](http://smarden.org/runit/svlogd.8.html), renamed in unix timestamp format and `gzip`-compressed (e.g. `@1584057562.s`).

## `unicorn_stderr.log`

This file lives in `/var/log/gitlab/unicorn/unicorn_stderr.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/unicorn_stderr.log` for
installations from source.

Unicorn is a high-performance forking Web server which is used for
serving the GitLab application. You can look at this log if, for
example, your application does not respond. This log contains all
information about the state of Unicorn processes at any given time.

```plaintext
I, [2015-02-13T06:14:46.680381 #9047]  INFO -- : Refreshing Gem list
I, [2015-02-13T06:14:56.931002 #9047]  INFO -- : listening on addr=127.0.0.1:8080 fd=12
I, [2015-02-13T06:14:56.931381 #9047]  INFO -- : listening on addr=/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket fd=13
I, [2015-02-13T06:14:56.936638 #9047]  INFO -- : master process ready
I, [2015-02-13T06:14:56.946504 #9092]  INFO -- : worker=0 spawned pid=9092
I, [2015-02-13T06:14:56.946943 #9092]  INFO -- : worker=0 ready
I, [2015-02-13T06:14:56.947892 #9094]  INFO -- : worker=1 spawned pid=9094
I, [2015-02-13T06:14:56.948181 #9094]  INFO -- : worker=1 ready
W, [2015-02-13T07:16:01.312916 #9094]  WARN -- : #<Unicorn::HttpServer:0x0000000208f618>: worker (pid: 9094) exceeds memory limit (320626688 bytes > 247066940 bytes)
W, [2015-02-13T07:16:01.313000 #9094]  WARN -- : Unicorn::WorkerKiller send SIGQUIT (pid: 9094) alive: 3621 sec (trial 1)
I, [2015-02-13T07:16:01.530733 #9047]  INFO -- : reaped #<Process::Status: pid 9094 exit 0> worker=1
I, [2015-02-13T07:16:01.534501 #13379]  INFO -- : worker=1 spawned pid=13379
I, [2015-02-13T07:16:01.534848 #13379]  INFO -- : worker=1 ready
```

## `repocheck.log`

This file lives in `/var/log/gitlab/gitlab-rails/repocheck.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/repocheck.log` for
installations from source.

It logs information whenever a [repository check is run][repocheck] on a project.

## `importer.log`

> Introduced in GitLab 11.3.

This file lives in `/var/log/gitlab/gitlab-rails/importer.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/importer.log` for
installations from source.

## `auth.log`

> Introduced in GitLab 12.0.

This file lives in `/var/log/gitlab/gitlab-rails/auth.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/auth.log` for
installations from source.

This log records:

- Information whenever [Rack Attack] registers an abusive request.
- Requests over the [Rate Limit] on raw endpoints.
- [Protected paths] abusive requests.

NOTE: **Note:**
From [%12.1](https://gitlab.com/gitlab-org/gitlab-foss/issues/62756), user ID and username are also
recorded on this log, if available.

## `graphql_json.log`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/59587) in GitLab 12.0.

This file lives in `/var/log/gitlab/gitlab-rails/graphql_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/graphql_json.log` for
installations from source.

GraphQL queries are recorded in that file. For example:

```json
{"query_string":"query IntrospectionQuery{__schema {queryType { name },mutationType { name }}}...(etc)","variables":{"a":1,"b":2},"complexity":181,"depth":1,"duration":7}
```

## `migrations.log`

> Introduced in GitLab 12.3.

This file lives in `/var/log/gitlab/gitlab-rails/migrations.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/migrations.log` for
installations from source.

## `mail_room_json.log` (default)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/19186) in GitLab 12.6.

This file lives in `/var/log/gitlab/mail_room/mail_room_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/mail_room_json.log` for
installations from source.

This structured log file records internal activity in the `mail_room` gem.
Its name and path are configurable, so the name and path may not match the above.

## Reconfigure Logs

Reconfigure log files live in `/var/log/gitlab/reconfigure` for Omnibus GitLab
packages. Installations from source don't have reconfigure logs. A reconfigure log
is populated whenever `gitlab-ctl reconfigure` is run manually or as part of an upgrade.

Reconfigure logs files are named according to the UNIX timestamp of when the reconfigure
was initiated, such as `1509705644.log`

## `sidekiq_exporter.log` and `web_exporter.log`

If Prometheus metrics and the Sidekiq Exporter are both enabled, Sidekiq will
start a Web server and listen to the defined port (default: `8082`). Access logs
will be generated in `/var/log/gitlab/gitlab-rails/sidekiq_exporter.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/sidekiq_exporter.log` for
installations from source.

If Prometheus metrics and the Web Exporter are both enabled, Unicorn/Puma will
start a Web server and listen to the defined port (default: `8083`). Access logs
will be generated in `/var/log/gitlab/gitlab-rails/web_exporter.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/web_exporter.log` for
installations from source.

## `database_load_balancing.log` **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/15442) in GitLab 12.3.

Contains details of GitLab's [Database Load Balancing](database_load_balancing.md).
It's stored at:

- `/var/log/gitlab/gitlab-rails/database_load_balancing.log` for Omnibus GitLab packages.
- `/home/git/gitlab/log/database_load_balancing.log` for installations from source.

## `elasticsearch.log`

> Introduced in GitLab 12.6.

This file lives in
`/var/log/gitlab/gitlab-rails/elasticsearch.log` for Omnibus GitLab
packages or in `/home/git/gitlab/log/elasticsearch.log` for installations
from source.

It logs information related to the Elasticsearch Integration including
errors during indexing or searching Elasticsearch.

Each line contains a JSON line that can be ingested by services like Elasticsearch and Splunk.
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

This file lives in
`/var/log/gitlab/gitlab-rails/exceptions_json.log` for Omnibus GitLab
packages or in `/home/git/gitlab/log/exceptions_json.log` for installations
from source.

It logs the information about exceptions being tracked by `Gitlab::ErrorTracking` which provides a standard and consistent way of [processing rescued exceptions](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/logging.md#exception-handling).

Each line contains a JSON line that can be ingested by Elasticsearch. For example:

```json
{
  "severity": "ERROR",
  "time": "2019-12-17T11:49:29.485Z",
  "correlation_id": "AbDVUrrTvM1",
  "extra.server": {
    "os": {
      "name": "Darwin",
      "version": "Darwin Kernel Version 19.2.0",
      "build": "19.2.0",
    },
    "runtime": {
      "name": "ruby",
      "version": "ruby 2.6.5p114 (2019-10-01 revision 67812) [x86_64-darwin18]"
    }
  },
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

## `geo.log`

> Introduced in 9.5.

Geo stores structured log messages in a `geo.log` file. For Omnibus installations, this file is at `/var/log/gitlab/gitlab-rails/geo.log`.

This file contains information about when Geo attempts to sync repositories and files. Each line in the file contains a separate JSON entry that can be ingested into. For example, Elasticsearch or Splunk.

For example:

```json
{"severity":"INFO","time":"2017-08-06T05:40:16.104Z","message":"Repository update","project_id":1,"source":"repository","resync_repository":true,"resync_wiki":true,"class":"Gitlab::Geo::LogCursor::Daemon","cursor_delay_s":0.038}
```

This message shows that Geo detected that a repository update was needed for project `1`.

## Registry Logs

For Omnibus installations, Container Registry logs reside in `/var/log/gitlab/registry/current`.

## NGINX Logs

For Omnibus installations, NGINX logs reside in:

- `/var/log/gitlab/nginx/gitlab_access.log` contains a log of requests made to GitLab.
- `/var/log/gitlab/nginx/gitlab_error.log` contains a log of NGINX errors for GitLab.
- `/var/log/gitlab/nginx/gitlab_pages_access.log` contains a log of requests made to Pages static sites.
- `/var/log/gitlab/nginx/gitlab_pages_error.log` contains a log of NGINX errors for Pages static sites.
- `/var/log/gitlab/nginx/gitlab_registry_access.log` contains a log of requests made to the Container Registry.
- `/var/log/gitlab/nginx/gitlab_registry_error.log` contains a log of NGINX errors for the Container Regsitry.

Below is the default GitLab NGINX access log format:

```plaintext
$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"
```

[repocheck]: repository_checks.md
[Rack Attack]: ../security/rack_attack.md
[Rate Limit]: ../user/admin_area/settings/rate_limits_on_raw_endpoints.md
[Protected paths]: ../user/admin_area/settings/protected_paths.md
