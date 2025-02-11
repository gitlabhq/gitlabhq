---
stage: Monitor
group: Platform Insights
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Logging development guidelines
---

[GitLab Logs](../administration/logs/_index.md) play a critical role for both
administrators and GitLab team members to diagnose problems in the field.

## Don't use `Rails.logger`

Currently `Rails.logger` calls all get saved into `production.log`, which contains
a mix of Rails' logs and other calls developers have inserted in the codebase.
For example:

```plaintext
Started GET "/gitlabhq/yaml_db/tree/master" for 168.111.56.1 at 2015-02-12 19:34:53 +0200
Processing by Projects::TreeController#show as HTML
  Parameters: {"project_id"=>"gitlabhq/yaml_db", "id"=>"master"}

  ...

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

These logs suffer from a number of problems:

1. They often lack timestamps or other contextual information (for example, project ID or user)
1. They may span multiple lines, which make them hard to find via Elasticsearch.
1. They lack a common structure, which make them hard to parse by log
   forwarders, such as Logstash or Fluentd. This also makes them hard to
   search.

Currently on GitLab.com, any messages in `production.log` aren't
indexed by Elasticsearch due to the sheer volume and noise. They
do end up in Google Stackdriver, but it is still harder to search for
logs there. See the [GitLab.com logging documentation](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging)
for more details.

## Use structured (JSON) logging

Structured logging solves these problems. Consider the example from an API request:

```json
{"time":"2018-10-29T12:49:42.123Z","severity":"INFO","duration":709.08,"db":14.59,"view":694.49,"status":200,"method":"GET","path":"/api/v4/projects","params":[{"key":"action","value":"git-upload-pack"},{"key":"changes","value":"_any"},{"key":"key_id","value":"secret"},{"key":"secret_token","value":"[FILTERED]"}],"host":"localhost","ip":"::1","ua":"Ruby","route":"/api/:version/projects","user_id":1,"username":"root","queue_duration":100.31,"gitaly_calls":30}
```

In a single line, we've included all the information that a user needs
to understand what happened: the timestamp, HTTP method and path, user
ID, and so on.

### How to use JSON logging

Suppose you want to log the events that happen in a project
importer. You want to log issues created, merge requests, and so on, as the
importer progresses. Here's what to do:

1. Look at [the list of GitLab Logs](../administration/logs/_index.md) to see
   if your log message might belong with one of the existing log files.
1. If there isn't a good place, consider creating a new filename, but
   check with a maintainer if it makes sense to do so. A log file should
   make it easy for people to search pertinent logs in one place. For
   example, `geo.log` contains all logs pertaining to GitLab Geo.
   To create a new file:
   1. Choose a filename (for example, `importer_json.log`).
   1. Create a new subclass of `Gitlab::JsonLogger`:

      ```ruby
      module Gitlab
        module Import
          class Logger < ::Gitlab::JsonLogger
            def self.file_name_noext
              'importer'
            end
          end
         end
      end
      ```

      By default, `Gitlab::JsonLogger` will include application context metadata in the log entry. If your
      logger is expected to be called outside of an application request (for example, in a `rake` task) or by low-level
      code that may be involved in building the application context (for example, database connection code), you should
      call the class method `exclude_context!` for your logger class, like so:

      ```ruby
      module Gitlab
        module Database
          module LoadBalancing
            class Logger < ::Gitlab::JsonLogger
              exclude_context!

              def self.file_name_noext
                'database_load_balancing'
              end
            end
          end
        end
      end

      ```

   1. In your class where you want to log, you might initialize the logger as an instance variable:

      ```ruby
      attr_accessor :logger

      def initialize
        @logger = ::Import::Framework::Logger.build
      end
      ```

      It is useful to memoize the logger because creating a new logger
      each time you log opens a file adds unnecessary overhead.

1. Now insert log messages into your code. When adding logs,
   make sure to include all the context as key-value pairs:

   ```ruby
   # BAD
   logger.info("Unable to create project #{project.id}")
   ```

   ```ruby
   # GOOD
   logger.info(message: "Unable to create project", project_id: project.id)
   ```

1. Be sure to create a common base structure of your log messages. For example,
   all messages might have `current_user_id` and `project_id` to make it easier
   to search for activities by user for a given time.

#### Implicit schema for JSON logging

When using something like Elasticsearch to index structured logs, there is a
schema for the types of each log field (even if that schema is implicit /
inferred). It's important to be consistent with the types of your field values,
otherwise this might break the ability to search/filter on these fields, or even
cause whole log events to be dropped. While much of this section is phrased in
an Elasticsearch-specific way, the concepts should translate to many systems you
might use to index structured logs. GitLab.com uses Elasticsearch to index log
data.

Unless a field type is explicitly mapped, Elasticsearch infers the type from
the first instance of that field value it sees. Subsequent instances of that
field value with different types either fail to be indexed, or in some
cases (scalar/object conflict), the whole log line is dropped.

GitLab.com's logging Elasticsearch sets
[`ignore_malformed`](https://www.elastic.co/guide/en/elasticsearch/reference/current/ignore-malformed.html),
which allows documents to be indexed even when there are simpler sorts of
mapping conflict (for example, number / string), although indexing on the affected fields
breaks.

Examples:

```ruby
# GOOD
logger.info(message: "Import error", error_code: 1, error: "I/O failure")

# BAD
logger.info(message: "Import error", error: 1)
logger.info(message: "Import error", error: "I/O failure")

# WORST
logger.info(message: "Import error", error: "I/O failure")
logger.info(message: "Import error", error: { message: "I/O failure" })
```

List elements must be the same type:

```ruby
# GOOD
logger.info(a_list: ["foo", "1", "true"])

# BAD
logger.info(a_list: ["foo", 1, true])
```

Resources:

- [Elasticsearch mapping - avoiding type gotchas](https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping.html#_avoiding_type_gotchas)
- [Elasticsearch mapping types](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-types.html)

#### Include a class attribute

Structured logs should always include a `class` attribute to make all entries logged from a particular place in the code findable.
To automatically add the `class` attribute, you can include the
[`Gitlab::Loggable` module](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/loggable.rb) and use the `build_structured_payload` method.

```ruby
class MyClass
  include ::Gitlab::Loggable

  def my_method
    logger.info(build_structured_payload(message: 'log message', project_id: project_id))
  end

  private

  def logger
    @logger ||= Gitlab::AppJsonLogger.build
  end
end
```

#### Logging durations

Similar to timezones, choosing the right time unit to log can impose avoidable overhead. So, whenever
challenged to choose between seconds, milliseconds or any other unit, lean towards _seconds_ as float
(with microseconds precision, that is, `Gitlab::InstrumentationHelper::DURATION_PRECISION`).

In order to make it easier to track timings in the logs, make sure the log key has `_s` as
suffix and `duration` within its name (for example, `view_duration_s`).

## Multi-destination Logging

GitLab transitioned from structured to JSON logs. However, through multi-destination logging, the logs can be recorded in multiple formats.

### How to use multi-destination logging

Create a new logger class, inheriting from `MultiDestinationLogger` and add an
array of loggers to a `LOGGERS` constant. The loggers should be classes that
descend from `Gitlab::Logger`. For example, the user-defined loggers in the
following examples could be inheriting from `Gitlab::Logger` and
`Gitlab::JsonLogger`, respectively.

You must specify one of the loggers as the `primary_logger`. The
`primary_logger` is used when information about this multi-destination logger is
displayed in the application (for example, using the `Gitlab::Logger.read_latest`
method).

The following example sets one of the defined `LOGGERS` as a `primary_logger`.

```ruby
module Gitlab
  class FancyMultiLogger < Gitlab::MultiDestinationLogger
    LOGGERS = [UnstructuredLogger, StructuredLogger].freeze

    def self.loggers
      LOGGERS
    end

    def primary_logger
      UnstructuredLogger
    end
  end
end
```

You can now call the usual logging methods on this multi-logger. For example:

```ruby
FancyMultiLogger.info(message: "Information")
```

This message is logged by each logger registered in `FancyMultiLogger.loggers`.

### Passing a string or hash for logging

When passing a string or hash to a `MultiDestinationLogger`, the log lines could be formatted differently, depending on the kinds of `LOGGERS` set.

For example, let's partially define the loggers from the previous example:

```ruby
module Gitlab
  # Similar to AppTextLogger
  class UnstructuredLogger < Gitlab::Logger
    ...
  end

  # Similar to AppJsonLogger
  class StructuredLogger < Gitlab::JsonLogger
    ...
  end
end
```

Here are some examples of how messages would be handled by both the loggers.

1. When passing a string

```ruby
FancyMultiLogger.info("Information")

# UnstructuredLogger
I, [2020-01-13T18:48:49.201Z #5647]  INFO -- : Information

# StructuredLogger
{:severity=>"INFO", :time=>"2020-01-13T11:02:41.559Z", :correlation_id=>"b1701f7ecc4be4bcd4c2d123b214e65a", :message=>"Information"}
```

1. When passing a hash

```ruby
FancyMultiLogger.info({:message=>"This is my message", :project_id=>123})

# UnstructuredLogger
I, [2020-01-13T19:01:17.091Z #11056]  INFO -- : {"message"=>"Message", "project_id"=>"123"}

# StructuredLogger
{:severity=>"INFO", :time=>"2020-01-13T11:06:09.851Z", :correlation_id=>"d7e0886f096db9a8526a4f89da0e45f6", :message=>"This is my message", :project_id=>123}
```

### Logging context metadata (through Rails or Grape requests)

`Gitlab::ApplicationContext` stores metadata in a request
lifecycle, which can then be added to the web request
or Sidekiq logs.

The API, Rails and Sidekiq logs contain fields starting with `meta.` with this context information.

Entry points can be seen at:

- [`ApplicationController`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/application_controller.rb)
- [External API](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/api.rb)
- [Internal API](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/api/internal/base.rb)

#### Adding attributes

When adding new attributes, make sure they're exposed within the context of the entry points above and:

- Pass them within the hash to the `with_context` (or `push`) method (make sure to pass a Proc if the
  method or variable shouldn't be evaluated right away)
- Change `Gitlab::ApplicationContext` to accept these new values
- Make sure the new attributes are accepted at [`Labkit::Context`](https://gitlab.com/gitlab-org/ruby/gems/labkit-ruby/-/blob/master/lib/labkit/context.rb)

See our <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [HOWTO: Use Sidekiq metadata logs](https://www.youtube.com/watch?v=_wDllvO_IY0) for further knowledge on
creating visualizations in Kibana.

The fields of the context are currently only logged for Sidekiq jobs triggered
through web requests. See the
[follow-up work](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/68)
for more information.

### Logging context metadata (through workers)

Additional metadata can be attached to a worker through the use of the [`ApplicationWorker#log_extra_metadata_on_done`](https://gitlab.com/gitlab-org/gitlab/-/blob/16ecc33341a3f6b6bebdf78d863c5bce76b040d3/app/workers/concerns/application_worker.rb#L31-34)
method. Using this method adds metadata that is later logged to Kibana with the done job payload.

```ruby
class MyExampleWorker
  include ApplicationWorker

  def perform(*args)
    # Worker performs work
    # ...

    # The contents of value will appear in Kibana under `json.extra.my_example_worker.my_key`
    log_extra_metadata_on_done(:my_key, value)
  end
end
```

See [this example](https://gitlab.com/gitlab-org/gitlab/-/blob/16ecc33341a3f6b6bebdf78d863c5bce76b040d3/app/workers/ci/pipeline_artifacts/expire_artifacts_worker.rb#L20-21)
which logs a count of how many artifacts are destroyed per run of the `ExpireArtifactsWorker`.

## Exception Handling

It often happens that you catch the exception and want to track it.

It should be noted that manual logging of exceptions is not allowed, as:

1. Manual logged exceptions can leak confidential data,
1. Manual logged exception very often require to clean backtrace
   which reduces the boilerplate,
1. Very often manually logged exception needs to be tracked to Sentry as well,
1. Manually logged exceptions does not use `correlation_id`, which makes hard
   to pin them to request, user and context in which this exception was raised,
1. Manually logged exceptions often end up across
   multiple files, which increases burden scraping all logging files.

To avoid duplicating and having consistent behavior the `Gitlab::ErrorTracking`
provides helper methods to track exceptions:

1. `Gitlab::ErrorTracking.track_and_raise_exception`: this method logs,
   sends exception to Sentry (if configured) and re-raises the exception,
1. `Gitlab::ErrorTracking.track_exception`: this method only logs
   and sends exception to Sentry (if configured),
1. `Gitlab::ErrorTracking.log_exception`: this method only logs the exception,
   and does not send the exception to Sentry,
1. `Gitlab::ErrorTracking.track_and_raise_for_dev_exception`: this method logs,
   sends exception to Sentry (if configured) and re-raises the exception
  for development and test environments.

It is advised to only use `Gitlab::ErrorTracking.track_and_raise_exception`
and `Gitlab::ErrorTracking.track_exception` as presented on below examples.

Consider adding additional extra parameters to provide more context
for each tracked exception.

### Example

```ruby
class MyService < ::BaseService
  def execute
    project.perform_expensive_operation

    success
  rescue => e
    Gitlab::ErrorTracking.track_exception(e, project_id: project.id)

    error('Exception occurred')
  end
end
```

```ruby
class MyService < ::BaseService
  def execute
    project.perform_expensive_operation

    success
  rescue => e
    Gitlab::ErrorTracking.track_and_raise_exception(e, project_id: project.id)
  end
end
```

## Default logging locations

For GitLab Self-Managed and GitLab.com, GitLab is deployed in two ways:

- [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab)
- [Cloud Native GitLab](https://gitlab.com/gitlab-org/build/CNG) via a [Helm Chart](https://gitlab.com/gitlab-org/charts/gitlab)

### Omnibus GitLab log handling

Omnibus GitLab logs inside component-specific directories within `/var/log/gitlab`:

```shell
# ls -al /var/log/gitlab
total 200
drwxr-xr-x 27 root              root        4096 Apr 29 20:28 .
drwxrwxr-x 19 root              syslog      4096 Aug  5 04:08 ..
drwx------  2 gitlab-prometheus root        4096 Aug  6 04:08 alertmanager
drwx------  2 root              root        4096 Aug  6 04:08 crond
drwx------  2 git               root        4096 Aug  6 04:08 gitaly
drwx------  2 git               root        4096 Aug  6 04:08 gitlab-exporter
drwx------  2 git               root        4096 Aug  6 04:08 gitlab-kas
drwx------  2 git               root       45056 Aug  6 13:18 gitlab-rails
drwx------  2 git               root        4096 Aug  5 04:18 gitlab-shell
drwx------  2 git               root        4096 May 24  2023 gitlab-sshd
drwx------  2 git               root        4096 Aug  6 04:08 gitlab-workhorse
drwxr-xr-x  2 root              root       12288 Aug  1 00:20 lets-encrypt
drwx------  2 root              root        4096 Aug  6 04:08 logrotate
drwx------  2 git               root        4096 Aug  6 04:08 mailroom
drwxr-x---  2 root              gitlab-www 12288 Aug  6 00:18 nginx
drwx------  2 gitlab-prometheus root        4096 Aug  6 04:08 node-exporter
drwx------  2 gitlab-psql       root        4096 Aug  6 15:00 pgbouncer
drwx------  2 gitlab-psql       root        4096 Aug  6 04:08 postgres-exporter
drwx------  2 gitlab-psql       root        4096 Aug  6 04:08 postgresql
drwx------  2 gitlab-prometheus root        4096 Aug  6 04:08 prometheus
drwx------  2 git               root        4096 Aug  6 04:08 puma
drwxr-xr-x  2 root              root       32768 Aug  1 21:32 reconfigure
drwx------  2 gitlab-redis      root        4096 Aug  6 04:08 redis
drwx------  2 gitlab-redis      root        4096 Aug  6 04:08 redis-exporter
drwx------  2 registry          root        4096 Aug  6 04:08 registry
drwx------  2 gitlab-redis      root        4096 May  6 06:30 sentinel
drwx------  2 git               root        4096 Aug  6 13:05 sidekiq
```

You can see in the example above that the following components store
logs in the following directories:

|Component|Log directory|
|---------|-------------|
|GitLab Rails|`/var/log/gitlab/gitlab-rails`|
|Gitaly|`/var/log/gitlab/gitaly`|
|Sidekiq|`/var/log/gitlab/sidekiq`|
|GitLab Workhorse|`/var/log/gitlab/gitlab-workhorse`|

The GitLab Rails directory is probably where you want to look for the
log files used with the Ruby code above.

[`logrotate`](https://github.com/logrotate/logrotate) is used to [watch for all *.log files](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/7e955ff25cf4dcc318b22724cc156a0daba33049/files/gitlab-cookbooks/logrotate/templates/default/logrotate-service.erb#L4).

### Cloud Native GitLab log handling

A Cloud Native GitLab pod writes GitLab logs directly to
`/var/log/gitlab` without creating additional subdirectories. For
example, the `webservice` pod runs `gitlab-workhorse` in one container
and `puma` in another. The log file directory in the latter looks like:

```shell
git@gitlab-webservice-default-bbd9647d9-fpwg5:/$ ls -al /var/log/gitlab
total 181420
drwxr-xr-x 2 git  git       4096 Aug  2 22:58 .
drwxr-xr-x 4 root root      4096 Aug  2 22:57 ..
-rw-r--r-- 1 git  git          0 Aug  2 18:22 .gitkeep
-rw-r--r-- 1 git  git   46524128 Aug  6 20:18 api_json.log
-rw-r--r-- 1 git  git      19009 Aug  2 22:58 application_json.log
-rw-r--r-- 1 git  git        157 Aug  2 22:57 auth_json.log
-rw-r--r-- 1 git  git       1116 Aug  2 22:58 database_load_balancing.log
-rw-r--r-- 1 git  git         67 Aug  2 22:57 grpc.log
-rw-r--r-- 1 git  git          0 Aug  2 22:57 production.log
-rw-r--r-- 1 git  git  138436632 Aug  6 20:18 production_json.log
-rw-r--r-- 1 git  git         48 Aug  2 22:58 puma.stderr.log
-rw-r--r-- 1 git  git        266 Aug  2 22:58 puma.stdout.log
-rw-r--r-- 1 git  git         67 Aug  2 22:57 service_measurement.log
-rw-r--r-- 1 git  git         67 Aug  2 22:57 sidekiq_client.log
-rw-r--r-- 1 git  git     733809 Aug  6 20:18 web_exporter.log
```

[`gitlab-logger`](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger)
is used to tail all files in `/var/log/gitlab`. Each log line is
converted to JSON if necessary and sent to `stdout` so that it can be
viewed via `kubectl logs`.

## Additional steps with new log files

1. Consider log retention settings. By default, Omnibus rotates any
   logs in `/var/log/gitlab/gitlab-rails/*.log` every hour and
   [keep at most 30 compressed files](https://docs.gitlab.com/omnibus/settings/logs.html#logrotate).
   On GitLab.com, that setting is only 6 compressed files. These settings should suffice
   for most users, but you may need to tweak them in [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab).

1. On GitLab.com all new JSON log files generated by GitLab Rails are
   automatically shipped to Elasticsearch (and available in Kibana) on GitLab
   Rails Kubernetes pods. If you need the file forwarded from Gitaly nodes then
   submit an issue to the
   [production tracker](https://gitlab.com/gitlab-com/gl-infra/production/-/issues)
   or a merge request to the
   [`gitlab_fluentd`](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd)
   project. See
   [this example](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/-/merge_requests/51/diffs).

1. Be sure to update the [GitLab CE/EE documentation](../administration/logs/_index.md) and the
   [GitLab.com runbooks](https://gitlab.com/gitlab-com/runbooks/blob/master/docs/logging/README.md).

## Finding new log files in Kibana (GitLab.com only)

On GitLab.com all new JSON log files generated by GitLab Rails are
automatically shipped to Elasticsearch (and available in Kibana) on GitLab
Rails Kubernetes pods. The `json.subcomponent` field in Kibana will allow you
to filter by the different kinds of log files. For example the
`json.subcomponent` will be `production_json` for entries forwarded from
`production_json.log`.

It's also worth noting that log files from Web/API pods go to a different
index than log files from Sidekiq pods. Depending on where you log from you
will find the logs in a different index pattern.

## Control logging visibility

An increase in the logs can cause a growing backlog of unacknowledged messages. When adding new log messages, make sure they don't increase the overall volume of logging by more than 10%.

### Deprecation notices

If the expected volume of deprecation notices is large:

- Only log them in the development environment.
- If needed, log them in the testing environment.
