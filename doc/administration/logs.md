# Log system

GitLab has an advanced log system where everything is logged so that you
can analyze your instance using various system log files. In addition to
system log files, GitLab Enterprise Edition comes with Audit Events.
Find more about them [in Audit Events
documentation](audit_events.md)

System log files are typically plain text in a standard log file format.
This guide talks about how to read and use these system log files.

## `production_json.log`

This file lives in `/var/log/gitlab/gitlab-rails/production_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/production_json.log` for
installations from source. (When GitLab is running in an environment
other than production, the corresponding logfile is shown here.)

It contains a structured log for Rails controller requests received from
GitLab, thanks to [Lograge](https://github.com/roidrage/lograge/). Note that
requests from the API are logged to a separate file in `api_json.log`.

Each line contains a JSON line that can be ingested by Elasticsearch, Splunk, etc. For example:

```json
{"method":"GET","path":"/gitlab/gitlab-foss/issues/1234","format":"html","controller":"Projects::IssuesController","action":"show","status":200,"duration":229.03,"view":174.07,"db":13.24,"time":"2017-08-08T20:15:54.821Z","params":[{"key":"param_key","value":"param_value"}],"remote_ip":"18.245.0.1","user_id":1,"username":"admin","gitaly_calls":76,"gitaly_duration":7.41,"queue_duration": 112.47}
```

In this example, you can see this was a GET request for a specific
issue. Notice each line also contains performance data. All times are in
milliseconds:

1. `duration`: total time taken to retrieve the request
1. `queue_duration`: total time that the request was queued inside GitLab Workhorse
1. `view`: total time taken inside the Rails views
1. `db`: total time to retrieve data from the database
1. `gitaly_calls`: total number of calls made to Gitaly
1. `gitaly_duration`: total time taken by Gitaly calls

User clone/fetch activity using http transport appears in this log as `action: git_upload_pack`.

In addition, the log contains the IP address from which the request originated
(`remote_ip`) as well as the user's ID (`user_id`), and username (`username`).

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
  "duration": 2584.11,
  "view": 0,
  "db": 9.21,
  "time": "2019-11-14T13:12:46.156Z",
  "params": [],
  "remote_ip": "127.0.0.1",
  "user_id": 1,
  "username": "root",
  "ua": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:70.0) Gecko/20100101 Firefox/70.0",
  "queue_duration": 274.35,
  "correlation_id": "KjDVUhNvvV3",
  "cpu_s": 2.837645135999999,
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
other than production, the corresponding logfile is shown here.)

It contains information about all performed requests. You can see the
URL and type of request, IP address and what exactly parts of code were
involved to service this particular request. Also you can see all SQL
request that have been performed and how much time it took. This task is
more useful for GitLab contributors and developers. Use part of this log
file when you are going to report bug. For example:

```
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

In this example we can see that server processed an HTTP request with URL
`/gitlabhq/yaml_db/tree/master` from IP 168.111.56.1 at 2015-02-12
19:34:53 +0200. Also we can see that request was processed by
`Projects::TreeController`.

## `api_json.log`

Introduced in GitLab 10.0, this file lives in
`/var/log/gitlab/gitlab-rails/api_json.log` for Omnibus GitLab packages or in
`/home/git/gitlab/log/api_json.log` for installations from source.

It helps you see requests made directly to the API. For example:

```json
{"time":"2018-10-29T12:49:42.123Z","severity":"INFO","duration":709.08,"db":14.59,"view":694.49,"status":200,"method":"GET","path":"/api/v4/projects","params":[{"key":"action","value":"git-upload-pack"},{"key":"changes","value":"_any"},{"key":"key_id","value":"secret"},{"key":"secret_token","value":"[FILTERED]"}],"host":"localhost","remote_ip":"::1","ua":"Ruby","route":"/api/:version/projects","user_id":1,"username":"root","queue_duration":100.31,"gitaly_calls":30,"gitaly_duration":5.36}
```

This entry above shows an access to an internal endpoint to check whether an
associated SSH key can download the project in question via a `git fetch` or
`git clone`. In this example, we see:

1. `duration`: total time in milliseconds taken to retrieve the request
1. `queue_duration`: total time in milliseconds that the request was queued inside GitLab Workhorse
1. `method`: The HTTP method used to make the request
1. `path`: The relative path of the query
1. `params`: Key-value pairs passed in a query string or HTTP body. Sensitive parameters (e.g. passwords, tokens, etc.) are filtered out.
1. `ua`: The User-Agent of the requester

## `application.log`

This file lives in `/var/log/gitlab/gitlab-rails/application.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/application.log` for
installations from source.

It helps you discover events happening in your instance such as user creation,
project removing and so on. For example:

```
October 06, 2014 11:56: User "Administrator" (admin@example.com) was created
October 06, 2014 11:56: Documentcloud created a new project "Documentcloud / Underscore"
October 06, 2014 11:56: Gitlab Org created a new project "Gitlab Org / Gitlab Ce"
October 07, 2014 11:25: User "Claudie Hodkiewicz" (nasir_stehr@olson.co.uk)  was removed
October 07, 2014 11:25: Project "project133" was removed
```

## `integrations_json.log`

This file lives in `/var/log/gitlab/gitlab-rails/integrations_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/integrations_json.log` for
installations from source.

It contains information about [integrations](../user/project/integrations/project_services.md) activities such as Jira, Asana and Irker services. It uses JSON format like the example below:

``` json
{"severity":"ERROR","time":"2018-09-06T14:56:20.439Z","service_class":"JiraService","project_id":8,"project_path":"h5bp/html5-boilerplate","message":"Error sending message","client_url":"http://jira.gitlap.com:8080","error":"execution expired"}
{"severity":"INFO","time":"2018-09-06T17:15:16.365Z","service_class":"JiraService","project_id":3,"project_path":"namespace2/project2","message":"Successfully posted","client_url":"http://jira.example.com"}
```

## `kubernetes.log`

Introduced in GitLab 11.6. This file lives in
`/var/log/gitlab/gitlab-rails/kubernetes.log` for Omnibus GitLab
packages or in `/home/git/gitlab/log/kubernetes.log` for
installations from source.

It logs information related to the Kubernetes Integration including errors
during installing cluster applications on your GitLab managed Kubernetes
clusters.

Each line contains a JSON line that can be ingested by Elasticsearch, Splunk,
etc. For example:

```json
{"severity":"ERROR","time":"2018-11-23T15:14:54.652Z","exception":"Kubeclient::HttpError","error_code":401,"service":"Clusters::Applications::CheckInstallationProgressService","app_id":14,"project_ids":[1],"group_ids":[],"message":"Unauthorized"}
{"severity":"ERROR","time":"2018-11-23T15:42:11.647Z","exception":"Kubeclient::HttpError","error_code":null,"service":"Clusters::Applications::InstallService","app_id":2,"project_ids":[19],"group_ids":[],"message":"SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get local issuer certificate)"}
```

## `git_json.log`

This file lives in `/var/log/gitlab/gitlab-rails/git_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/git_json.log` for
installations from source.

NOTE: **Note:**
After 12.2, this file was renamed from `githost.log` to
`git_json.log` and stored in JSON format.

GitLab has to interact with Git repositories but in some rare cases
something can go wrong and in this case you will know what exactly
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
{"severity":"INFO","time":"2018-10-17T17:38:22.523Z","author_id":3,"entity_id":2,"entity_type":"Project","change":"visibility","from":"Private","to":"Public","author_name":"John Doe4","target_id":2,"target_type":"Project","target_details":"namespace2/project2"}
{"severity":"INFO","time":"2018-10-17T17:38:22.830Z","author_id":5,"entity_id":3,"entity_type":"Project","change":"name","from":"John Doe7 / project3","to":"John Doe7 / new name","author_name":"John Doe6","target_id":3,"target_type":"Project","target_details":"namespace3/project3"}
{"severity":"INFO","time":"2018-10-17T17:38:23.175Z","author_id":7,"entity_id":4,"entity_type":"Project","change":"path","from":"","to":"namespace4/newpath","author_name":"John Doe8","target_id":4,"target_type":"Project","target_details":"namespace4/newpath"}
```

## `sidekiq.log`

This file lives in `/var/log/gitlab/gitlab-rails/sidekiq.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/sidekiq.log` for
installations from source.

GitLab uses background jobs for processing tasks which can take a long
time. All information about processing these jobs are written down to
this file. For example:

```
2014-06-10T07:55:20Z 2037 TID-tm504 ERROR: /opt/bitnami/apps/discourse/htdocs/vendor/bundle/ruby/1.9.1/gems/redis-3.0.7/lib/redis/client.rb:228:in `read'
2014-06-10T18:18:26Z 14299 TID-55uqo INFO: Booting Sidekiq 3.0.0 with redis options {:url=>"redis://localhost:6379/0", :namespace=>"sidekiq"}
```

Instead of the format above, you can opt to generate JSON logs for
Sidekiq. For example:

```json
{"severity":"INFO","time":"2018-04-03T22:57:22.071Z","queue":"cronjob:update_all_mirrors","args":[],"class":"UpdateAllMirrorsWorker","retry":false,"queue_namespace":"cronjob","jid":"06aeaa3b0aadacf9981f368e","created_at":"2018-04-03T22:57:21.930Z","enqueued_at":"2018-04-03T22:57:21.931Z","pid":10077,"message":"UpdateAllMirrorsWorker JID-06aeaa3b0aadacf9981f368e: done: 0.139 sec","job_status":"done","duration":0.139,"completed_at":"2018-04-03T22:57:22.071Z"}
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

## `gitlab-shell.log`

This file lives in `/var/log/gitlab/gitlab-shell/gitlab-shell.log` for
Omnibus GitLab packages or in `/home/git/gitlab-shell/gitlab-shell.log` for
installations from source.

GitLab Shell is used by GitLab for executing Git commands and provide
SSH access to Git repositories. For example:

```
I, [2015-02-13T06:17:00.671315 #9291]  INFO -- : Adding project root/example.git at </var/opt/gitlab/git-data/repositories/root/dcdcdcdcd.git>.
I, [2015-02-13T06:17:00.679433 #9291]  INFO -- : Moving existing hooks directory and symlinking global hooks directory for /var/opt/gitlab/git-data/repositories/root/example.git.
```

User clone/fetch activity using SSH transport appears in this log as `executing git command <gitaly-upload-pack...`.

## `unicorn_stderr.log`

This file lives in `/var/log/gitlab/unicorn/unicorn_stderr.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/unicorn_stderr.log` for
installations from source.

Unicorn is a high-performance forking Web server which is used for
serving the GitLab application. You can look at this log if, for
example, your application does not respond. This log contains all
information about the state of Unicorn processes at any given time.

```
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

Introduced in GitLab 11.3. This file lives in `/var/log/gitlab/gitlab-rails/importer.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/importer.log` for
installations from source.

## `auth.log`

Introduced in GitLab 12.0. This file lives in `/var/log/gitlab/gitlab-rails/auth.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/auth.log` for
installations from source.

This log records:

- Information whenever [Rack Attack] registers an abusive request.
- Requests over the [Rate Limit] on raw endpoints.
- [Protected paths] abusive requests.

NOTE: **Note:**
From [%12.1](https://gitlab.com/gitlab-org/gitlab-foss/issues/62756), user id and username are also
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

Introduced in GitLab 12.3. This file lives in `/var/log/gitlab/gitlab-rails/migrations.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/migrations.log` for
installations from source.

## `mail_room_json.log` (default)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/19186) in GitLab 12.6.

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
start a Web server and listen to the defined port (default: 8082). Access logs
will be generated in `/var/log/gitlab/gitlab-rails/sidekiq_exporter.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/sidekiq_exporter.log` for
installations from source.

If Prometheus metrics and the Web Exporter are both enabled, Unicorn/Puma will
start a Web server and listen to the defined port (default: 8083). Access logs
will be generated in `/var/log/gitlab/gitlab-rails/web_exporter.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/web_exporter.log` for
installations from source.

## `database_load_balancing.log` **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/15442) in GitLab 12.3.

Contains details of GitLab's [Database Load Balancing](database_load_balancing.md).
It is stored at:

- `/var/log/gitlab/gitlab-rails/database_load_balancing.log` for Omnibus GitLab packages.
- `/home/git/gitlab/log/database_load_balancing.log` for installations from source.

## `elasticsearch.log`

Introduced in GitLab 12.6. This file lives in
`/var/log/gitlab/gitlab-rails/elasticsearch.log` for Omnibus GitLab
packages or in `/home/git/gitlab/log/elasticsearch.log` for installations
from source.

It logs information related to the Elasticsearch Integration including
errors during indexing or searching Elasticsearch.

Each line contains a JSON line that can be ingested by Elasticsearch, Splunk,
etc. For example:

```json
{"severity":"DEBUG","time":"2019-10-17T06:23:13.227Z","correlation_id":null,"message":"redacted_search_result","class_name":"Milestone","id":2,"ability":"read_milestone","current_user_id":2,"query":"project"}
```

[repocheck]: repository_checks.md
[Rack Attack]: ../security/rack_attack.md
[Rate Limit]: ../user/admin_area/settings/rate_limits_on_raw_endpoints.md
[Protected paths]: ../user/admin_area/settings/protected_paths.md
