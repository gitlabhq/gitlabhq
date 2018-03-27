# Log system

GitLab has an advanced log system where everything is logged so that you
can analyze your instance using various system log files. In addition to
system log files, GitLab Enterprise Edition comes with Audit Events.
Find more about them [in Audit Events
documentation](http://docs.gitlab.com/ee/administration/audit_events.html)

System log files are typically plain text in a standard log file format.
This guide talks about how to read and use these system log files.

## `production_json.log`

This file lives in `/var/log/gitlab/gitlab-rails/production_json.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/production_json.log` for
installations from source. (When Gitlab is running in an environment
other than production, the corresponding logfile is shown here.)

It contains a structured log for Rails controller requests received from
GitLab, thanks to [Lograge](https://github.com/roidrage/lograge/). Note that
requests from the API are logged to a separate file in `api_json.log`.

Each line contains a JSON line that can be ingested by Elasticsearch, Splunk, etc. For example:

```json
{"method":"GET","path":"/gitlab/gitlab-ce/issues/1234","format":"html","controller":"Projects::IssuesController","action":"show","status":200,"duration":229.03,"view":174.07,"db":13.24,"time":"2017-08-08T20:15:54.821Z","params":[{"key":"param_key","value":"param_value"}],"remote_ip":"18.245.0.1","user_id":1,"username":"admin","gitaly_calls":76}
```

In this example, you can see this was a GET request for a specific issue. Notice each line also contains performance data:

1. `duration`: the total time taken to retrieve the request
2. `view`: total time taken inside the Rails views
3. `db`: total time to retrieve data from the database
4. `gitaly_calls`: total number of calls made to Gitaly

User clone/fetch activity using http transport appears in this log as `action: git_upload_pack`.

In addition, the log contains the IP address from which the request originated
(`remote_ip`) as well as the user's ID (`user_id`), and username (`username`).

## `production.log`

This file lives in `/var/log/gitlab/gitlab-rails/production.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/production.log` for
installations from source. (When Gitlab is running in an environment
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
{"time":"2017-10-10T12:30:11.579Z","severity":"INFO","duration":16.84,"db":1.57,"view":15.27,"status":200,"method":"POST","path":"/api/v4/internal/allowed","params":{"action":"git-upload-pack","changes":"_any","gl_repository":null,"project":"root/foobar.git","protocol":"ssh","env":"{}","key_id":"[FILTERED]","secret_token":"[FILTERED]"},"host":"127.0.0.1","ip":"127.0.0.1","ua":"Ruby"}
```

This entry above shows an access to an internal endpoint to check whether an
associated SSH key can download the project in question via a `git fetch` or
`git clone`. In this example, we see:

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

## `githost.log`

This file lives in `/var/log/gitlab/gitlab-rails/githost.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/githost.log` for
installations from source.

GitLab has to interact with Git repositories but in some rare cases
something can go wrong and in this case you will know what exactly
happened. This log file contains all failed requests from GitLab to Git
repositories. In the majority of cases this file will be useful for developers
only. For example:

```
December 03, 2014 13:20 -> ERROR -> Command failed [1]: /usr/bin/git --git-dir=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq/.git --work-tree=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq merge --no-ff -mMerge branch 'feature_conflict' into 'feature' source/feature_conflict

error: failed to push some refs to '/Users/vsizov/gitlab-development-kit/repositories/gitlabhq/gitlab_git.git'
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

## `gitlab-shell.log`

This file lives in `/var/log/gitlab/gitlab-shell/gitlab-shell.log` for
Omnibus GitLab packages or in `/home/git/gitlab-shell/gitlab-shell.log` for
installations from source.

GitLab shell is used by Gitlab for executing Git commands and provide
SSH access to Git repositories. For example:

```
I, [2015-02-13T06:17:00.671315 #9291]  INFO -- : Adding project root/example.git at </var/opt/gitlab/git-data/repositories/root/dcdcdcdcd.git>.
I, [2015-02-13T06:17:00.679433 #9291]  INFO -- : Moving existing hooks directory and symlinking global hooks directory for /var/opt/gitlab/git-data/repositories/root/example.git.
```

User clone/fetch activity using ssh transport appears in this log as `executing git command <gitaly-upload-pack...`.

## `unicorn\_stderr.log`

This file lives in `/var/log/gitlab/unicorn/unicorn_stderr.log` for
Omnibus GitLab packages or in `/home/git/gitlab/log/unicorn_stderr.log` for
installations from source.

Unicorn is a high-performance forking Web server which is used for
serving the GitLab application. You can look at this log if, for
example, your application does not respond. This log contains all
information about the state of unicorn processes at any given time.

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

## Reconfigure Logs

Reconfigure log files live in `/var/log/gitlab/reconfigure` for Omnibus GitLab 
packages. Installations from source don't have reconfigure logs. A reconfigure log 
is populated whenever `gitlab-ctl reconfigure` is run manually or as part of an upgrade.

Reconfigure logs files are named according to the UNIX timestamp of when the reconfigure
was initiated, such as `1509705644.log`

[repocheck]: repository_checks.md
