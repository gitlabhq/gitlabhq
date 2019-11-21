# GitLab Developers Guide to Logging

[GitLab Logs](../administration/logs.md) play a critical role for both
administrators and GitLab team members to diagnose problems in the field.

## Don't use `Rails.logger`

Currently `Rails.logger` calls all get saved into `production.log`, which contains
a mix of Rails' logs and other calls developers have inserted in the code base.
For example:

```
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

1. They often lack timestamps or other contextual information (e.g. project ID, user)
1. They may span multiple lines, which make them hard to find via Elasticsearch.
1. They lack a common structure, which make them hard to parse by log
   forwarders, such as Logstash or Fluentd. This also makes them hard to
   search.

Note that currently on GitLab.com, any messages in `production.log` will
NOT get indexed by Elasticsearch due to the sheer volume and noise. They
do end up in Google Stackdriver, but it is still harder to search for
logs there. See the [GitLab.com logging
documentation](https://gitlab.com/gitlab-com/runbooks/blob/master/logging/doc/README.md)
for more details.

## Use structured (JSON) logging

Structured logging solves these problems. Consider the example from an API request:

```json
{"time":"2018-10-29T12:49:42.123Z","severity":"INFO","duration":709.08,"db":14.59,"view":694.49,"status":200,"method":"GET","path":"/api/v4/projects","params":[{"key":"action","value":"git-upload-pack"},{"key":"changes","value":"_any"},{"key":"key_id","value":"secret"},{"key":"secret_token","value":"[FILTERED]"}],"host":"localhost","ip":"::1","ua":"Ruby","route":"/api/:version/projects","user_id":1,"username":"root","queue_duration":100.31,"gitaly_calls":30}
```

In a single line, we've included all the information that a user needs
to understand what happened: the timestamp, HTTP method and path, user
ID, etc.

### How to use JSON logging

Suppose you want to log the events that happen in a project
importer. You want to log issues created, merge requests, etc. as the
importer progresses. Here's what to do:

1. Look at [the list of GitLab Logs](../administration/logs.md) to see
   if your log message might belong with one of the existing log files.
1. If there isn't a good place, consider creating a new filename, but
   check with a maintainer if it makes sense to do so. A log file should
   make it easy for people to search pertinent logs in one place. For
   example, `geo.log` contains all logs pertaining to GitLab Geo.
   To create a new file:
   1. Choose a filename (e.g. `importer_json.log`).
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

   1. In your class where you want to log, you might initialize the logger as an instance variable:

      ```ruby
      attr_accessor :logger

      def initialize
        @logger = Gitlab::Import::Logger.build
      end
      ```

      Note that it's useful to memoize this because creating a new logger
      each time you log will open a file, adding unnecessary overhead.

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

1. Do NOT mix and match types. Elasticsearch won't be able to index your
   logs properly if you [mix integer and string
   types](https://www.elastic.co/guide/en/elasticsearch/guide/current/mapping.html#_avoiding_type_gotchas):

   ```ruby
   # BAD
   logger.info(message: "Import error", error: 1)
   logger.info(message: "Import error", error: "I/O failure")
   ```

   ```ruby
   # GOOD
   logger.info(message: "Import error", error_code: 1, error: "I/O failure")
   ```

## Additional steps with new log files

1. Consider log retention settings. By default, Omnibus will rotate any
   logs in `/var/log/gitlab/gitlab-rails/*.log` every hour and [keep at
   most 30 compressed files](https://docs.gitlab.com/omnibus/settings/logs.html#logrotate).
   On GitLab.com, that setting is only 6 compressed files. These settings should suffice
   for most users, but you may need to tweak them in [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab).

1. If you add a new file, submit an issue to the [production
   tracker](https://gitlab.com/gitlab-com/gl-infra/production/issues) or
   a merge request to the [gitlab_fluentd](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd)
   project. See [this example](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd/merge_requests/51/diffs).

1. Be sure to update the [GitLab CE/EE documentation](../administration/logs.md) and the [GitLab.com
   runbooks](https://gitlab.com/gitlab-com/runbooks/blob/master/howto/logging.md).
