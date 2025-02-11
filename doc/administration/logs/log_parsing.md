---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Parsing GitLab logs with `jq`
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

We recommend using log aggregation and search tools like Kibana and Splunk whenever possible,
but if they are not available you can still quickly parse
[GitLab logs](../logs/_index.md) in JSON format
using [`jq`](https://stedolan.github.io/jq/).

NOTE:
Specifically for summarizing error events and basic usage statistics,
the GitLab Support Team provides the specialised
[`fast-stats` tool](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/#when-to-use-it).

## What is JQ?

As noted in its [manual](https://stedolan.github.io/jq/manual/), `jq` is a command-line JSON processor. The following examples
include use cases targeted for parsing GitLab log files.

## Parsing Logs

The examples listed below address their respective log files by
their relative Linux package installation paths and default filenames.
Find the respective full paths in the [GitLab logs sections](../logs/_index.md#production_jsonlog).

### Compressed logs

When [log files are rotated](https://smarden.org/runit/svlogd.8), they are renamed in
Unix timestamp format and compressed with `gzip`. The resulting file name looks like
`@40000000624492fa18da6f34.s`. These files must be handled differently before parsing,
than the more recent log files:

- To uncompress the file, use `gunzip -S .s @40000000624492fa18da6f34.s`, replacing
  the filename with your compressed log file's name.
- To read or pipe the file directly, use `zcat` or `zless`.
- To search file contents, use `zgrep`.

### General Commands

#### Pipe colorized `jq` output into `less`

```shell
jq . <FILE> -C | less -R
```

#### Search for a term and pretty-print all matching lines

```shell
grep <TERM> <FILE> | jq .
```

#### Skip invalid lines of JSON

```shell
jq -cR 'fromjson?' file.json | jq <COMMAND>
```

By default `jq` errors out when it encounters a line that is not valid JSON.
This skips over all invalid lines and parses the rest.

#### Print a JSON log's time range

```shell
cat log.json | (head -1; tail -1) | jq '.time'
```

Use `zcat` if the file has been rotated and compressed:

```shell
zcat @400000006026b71d1a7af804.s | (head -1; tail -1) | jq '.time'

zcat some_json.log.25.gz | (head -1; tail -1) | jq '.time'
```

#### Get activity for correlation ID across multiple JSON logs in chronological order

```shell
grep -hR <correlationID> | jq -c -R 'fromjson?' | jq -C -s 'sort_by(.time)'  | less -R
```

### Parsing `gitlab-rails/production_json.log` and `gitlab-rails/api_json.log`

#### Find all requests with a 5XX status code

```shell
jq 'select(.status >= 500)' <FILE>
```

#### Top 10 slowest requests

```shell
jq -s 'sort_by(-.duration_s) | limit(10; .[])' <FILE>
```

#### Find and pretty print all requests related to a project

```shell
grep <PROJECT_NAME> <FILE> | jq .
```

#### Find all requests with a total duration > 5 seconds

```shell
jq 'select(.duration_s > 5000)' <FILE>
```

#### Find all project requests with more than 5 Gitaly calls

```shell
grep <PROJECT_NAME> <FILE> | jq 'select(.gitaly_calls > 5)'
```

#### Find all requests with a Gitaly duration > 10 seconds

```shell
jq 'select(.gitaly_duration_s > 10000)' <FILE>
```

#### Find all requests with a queue duration > 10 seconds

```shell
jq 'select(.queue_duration_s > 10000)' <FILE>
```

#### Top 10 requests by # of Gitaly calls

```shell
jq -s 'map(select(.gitaly_calls != null)) | sort_by(-.gitaly_calls) | limit(10; .[])' <FILE>
```

#### Output a specific time range

```shell
jq 'select(.time >= "2023-01-10T00:00:00Z" and .time <= "2023-01-10T12:00:00Z")' <FILE>
```

### Parsing `gitlab-rails/production_json.log`

#### Print the top three controller methods by request volume and their three longest durations

```shell
jq -s -r 'group_by(.controller+.action) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tMETHOD: \(.[0].controller)#\(.[0].action)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' production_json.log
```

**Example output**

```plaintext
CT: 2721   METHOD: SessionsController#new  DURS: 844.06,  713.81,  704.66
CT: 2435   METHOD: MetricsController#index DURS: 299.29,  284.01,  158.57
CT: 1328   METHOD: Projects::NotesController#index DURS: 403.99,  386.29,  384.39
```

### Parsing `gitlab-rails/api_json.log`

#### Print top three routes with request count and their three longest durations

```shell
jq -s -r 'group_by(.route) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tROUTE: \(.[0].route)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' api_json.log
```

**Example output**

```plaintext
CT: 2472 ROUTE: /api/:version/internal/allowed   DURS: 56402.65,  38411.43,  19500.41
CT: 297  ROUTE: /api/:version/projects/:id/repository/tags       DURS: 731.39,  685.57,  480.86
CT: 190  ROUTE: /api/:version/projects/:id/repository/commits    DURS: 1079.02,  979.68,  958.21
```

#### Print top API user agents

```shell
jq --raw-output 'select(.remote_ip != "127.0.0.1") | [.remote_ip, .username, .route, .ua] | @tsv' api_json.log |
  sort | uniq -c | sort -n | tail
```

**Example output**:

```plaintext
  89 1.2.3.4, 127.0.0.1  some_user  /api/:version/projects/:id/pipelines  # plus browser details; OK
 567 5.6.7.8, 127.0.0.1      /api/:version/jobs/:id/trace gitlab-runner   # plus version details; OK
1234 98.76.54.31, 127.0.0.1  some_bot  /api/:version/projects/:id/repository/files/:file_path/raw
```

This example shows a custom tool or script causing an unexpectedly high number of requests.
User agents in this situation can be specialized [third-party clients](../../api/rest/third_party_clients.md),
or general tools like `curl`.

You can also use `fast-stats top` (see top of page) to extract performance statistics for those users or bots.

### Parsing `gitlab-rails/importer.log`

To troubleshoot [project imports](../raketasks/project_import_export.md) or
[migrations](../../user/project/import/_index.md), run this command:

```shell
jq 'select(.project_path == "<namespace>/<project>").error_messages' importer.log
```

For common issues, see [troubleshooting](../raketasks/import_export_rake_tasks_troubleshooting.md).

### Parsing `gitlab-workhorse/current`

#### Print top Workhorse user agents

```shell
jq --raw-output 'select(.remote_ip != "127.0.0.1") | [.remote_ip, .uri, .user_agent] | @tsv' current |
  sort | uniq -c | sort -n | tail
```

Similar to the [API `ua` example](#print-top-api-user-agents),
many unexpected user agents in this output indicate unoptimized scripts.
Expected user agents include `gitlab-runner`, `GitLab-Shell`, and browsers.

The performance impact of runners checking for new jobs can be reduced by increasing
[the `check_interval` setting](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section),
for example.

### Parsing `gitlab-rails/geo.log`

#### Find most common Geo sync errors

If [the `geo:status` Rake task](../geo/replication/troubleshooting/common.md#sync-status-rake-task)
repeatedly reports that some items never reach 100%,
the following command helps to focus on the most common errors.

```shell
jq --raw-output 'select(.severity == "ERROR") | [.project_path, .class, .message, .error] | @tsv' geo.log | sort | uniq -c | sort | tail
```

Refer to our [Geo troubleshooting page](../geo/replication/troubleshooting/_index.md)
for advice about specific error messages.

### Parsing `gitaly/current`

Use the following examples to [troubleshoot Gitaly](../gitaly/troubleshooting.md).

#### Find all Gitaly requests sent from web UI

```shell
jq 'select(."grpc.meta.client_name" == "gitlab-web")' current
```

#### Find all failed Gitaly requests

```shell
jq 'select(."grpc.code" != null and ."grpc.code" != "OK")' current
```

#### Find all requests that took longer than 30 seconds

```shell
jq 'select(."grpc.time_ms" > 30000)' current
```

#### Print top ten projects by request volume and their three longest durations

```shell
jq --raw-output --slurp '
  map(
    select(
      ."grpc.request.glProjectPath" != null
      and ."grpc.request.glProjectPath" != ""
      and ."grpc.time_ms" != null
    )
  )
  | group_by(."grpc.request.glProjectPath")
  | sort_by(-length)
  | limit(10; .[])
  | sort_by(-."grpc.time_ms")
  | [
      length,
      .[0]."grpc.time_ms",
      .[1]."grpc.time_ms",
      .[2]."grpc.time_ms",
      .[0]."grpc.request.glProjectPath"
    ]
  | @sh' current |
  awk 'BEGIN { printf "%7s %10s %10s %10s\t%s\n", "CT", "MAX DURS", "", "", "PROJECT" }
  { printf "%7u %7u ms, %7u ms, %7u ms\t%s\n", $1, $2, $3, $4, $5 }'
```

**Example output**

```plaintext
   CT    MAX DURS                              PROJECT
  206    4898 ms,    1101 ms,    1032 ms      'groupD/project4'
  109    1420 ms,     962 ms,     875 ms      'groupEF/project56'
  663     106 ms,      96 ms,      94 ms      'groupABC/project123'
  ...
```

#### Types of user and project activity overview

```shell
jq --raw-output '[.username, ."grpc.method", ."grpc.request.glProjectPath"] | @tsv' current | sort | uniq -c | sort -n
```

#### Find all projects affected by a fatal Git problem

```shell
grep "fatal: " current |
  jq '."grpc.request.glProjectPath"' |
  sort | uniq
```

### Parsing `gitlab-shell/gitlab-shell.log`

For investigating Git calls through SSH.

Find the top 20 calls by project and user:

```shell
jq --raw-output --slurp '
  map(
    select(
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```

Find the top 20 calls by project, user, and command:

```shell
jq --raw-output --slurp '
  map(
    select(
      .command  != null and
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path+.command)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tcommand: \(.[0].command)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```
