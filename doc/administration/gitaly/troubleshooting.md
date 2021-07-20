---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Troubleshooting Gitaly and Gitaly Cluster **(FREE SELF)**

Refer to the information below when troubleshooting Gitaly and Gitaly Cluster.

Before troubleshooting, see the Gitaly and Gitaly Cluster
[frequently asked questions](faq.md).

## Troubleshoot Gitaly

The following sections provide possible solutions to Gitaly errors.

See also [Gitaly timeout](../../user/admin_area/settings/gitaly_timeouts.md) settings.

### Check versions when using standalone Gitaly servers

When using standalone Gitaly servers, you must make sure they are the same version
as GitLab to ensure full compatibility:

1. On the top bar, select **Menu >** **{admin}** **Admin** on your GitLab instance.
1. On the left sidebar, select **Overview > Gitaly Servers**.
1. Confirm all Gitaly servers indicate that they are up to date.

### Use `gitaly-debug`

The `gitaly-debug` command provides "production debugging" tools for Gitaly and Git
performance. It is intended to help production engineers and support
engineers investigate Gitaly performance problems.

If you're using GitLab 11.6 or newer, this tool should be installed on
your GitLab or Gitaly server already at `/opt/gitlab/embedded/bin/gitaly-debug`.
If you're investigating an older GitLab version you can compile this
tool offline and copy the executable to your server:

```shell
git clone https://gitlab.com/gitlab-org/gitaly.git
cd cmd/gitaly-debug
GOOS=linux GOARCH=amd64 go build -o gitaly-debug
```

To see the help page of `gitaly-debug` for a list of supported sub-commands, run:

```shell
gitaly-debug -h
```

### Commits, pushes, and clones return a 401

```plaintext
remote: GitLab: 401 Unauthorized
```

You need to sync your `gitlab-secrets.json` file with your GitLab
application nodes.

### Client side gRPC logs

Gitaly uses the [gRPC](https://grpc.io/) RPC framework. The Ruby gRPC
client has its own log file which may contain useful information when
you are seeing Gitaly errors. You can control the log level of the
gRPC client with the `GRPC_LOG_LEVEL` environment variable. The
default level is `WARN`.

You can run a gRPC trace with:

```shell
sudo GRPC_TRACE=all GRPC_VERBOSITY=DEBUG gitlab-rake gitlab:gitaly:check
```

### Server side gRPC logs

gRPC tracing can also be enabled in Gitaly itself with the `GODEBUG=http2debug`
environment variable. To set this in an Omnibus GitLab install:

1. Add the following to your `gitlab.rb` file:

   ```ruby
   gitaly['env'] = {
     "GODEBUG=http2debug" => "2"
   }
   ```

1. [Reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab.

### Correlating Git processes with RPCs

Sometimes you need to find out which Gitaly RPC created a particular Git process.

One method for doing this is by using `DEBUG` logging. However, this needs to be enabled
ahead of time and the logs produced are quite verbose.

A lightweight method for doing this correlation is by inspecting the environment
of the Git process (using its `PID`) and looking at the `CORRELATION_ID` variable:

```shell
PID=<Git process ID>
sudo cat /proc/$PID/environ | tr '\0' '\n' | grep ^CORRELATION_ID=
```

This method isn't reliable for `git cat-file` processes, because Gitaly
internally pools and re-uses those across RPCs.

### Observing `gitaly-ruby` traffic

[`gitaly-ruby`](configure_gitaly.md#gitaly-ruby) is an internal implementation detail of Gitaly,
so, there's not that much visibility into what goes on inside
`gitaly-ruby` processes.

If you have Prometheus set up to scrape your Gitaly process, you can see
request rates and error codes for individual RPCs in `gitaly-ruby` by
querying `grpc_client_handled_total`.

- In theory, this metric does not differentiate between `gitaly-ruby` and other RPCs.
- In practice from GitLab 11.9, all gRPC calls made by Gitaly itself are internal calls from the
  main Gitaly process to one of its `gitaly-ruby` sidecars.

Assuming your `grpc_client_handled_total` counter only observes Gitaly,
the following query shows you RPCs are (most likely) internally
implemented as calls to `gitaly-ruby`:

```prometheus
sum(rate(grpc_client_handled_total[5m])) by (grpc_method) > 0
```

### Repository changes fail with a `401 Unauthorized` error

If you run Gitaly on its own server and notice these conditions:

- Users can successfully clone and fetch repositories by using both SSH and HTTPS.
- Users can't push to repositories, or receive a `401 Unauthorized` message when attempting to
  make changes to them in the web UI.

Gitaly may be failing to authenticate with the Gitaly client because it has the
[wrong secrets file](configure_gitaly.md#configure-gitaly-servers).

Confirm the following are all true:

- When any user performs a `git push` to any repository on this Gitaly server, it
  fails with a `401 Unauthorized` error:

  ```shell
  remote: GitLab: 401 Unauthorized
  To <REMOTE_URL>
  ! [remote rejected] branch-name -> branch-name (pre-receive hook declined)
  error: failed to push some refs to '<REMOTE_URL>'
  ```

- When any user adds or modifies a file from the repository using the GitLab
  UI, it immediately fails with a red `401 Unauthorized` banner.
- Creating a new project and [initializing it with a README](../../user/project/working_with_projects.md#blank-projects)
  successfully creates the project but doesn't create the README.
- When [tailing the logs](https://docs.gitlab.com/omnibus/settings/logs.html#tail-logs-in-a-console-on-the-server)
  on a Gitaly client and reproducing the error, you get `401` errors
  when reaching the [`/api/v4/internal/allowed`](../../development/internal_api.md) endpoint:

  ```shell
  # api_json.log
  {
    "time": "2019-07-18T00:30:14.967Z",
    "severity": "INFO",
    "duration": 0.57,
    "db": 0,
    "view": 0.57,
    "status": 401,
    "method": "POST",
    "path": "\/api\/v4\/internal\/allowed",
    "params": [
      {
        "key": "action",
        "value": "git-receive-pack"
      },
      {
        "key": "changes",
        "value": "REDACTED"
      },
      {
        "key": "gl_repository",
        "value": "REDACTED"
      },
      {
        "key": "project",
        "value": "\/path\/to\/project.git"
      },
      {
        "key": "protocol",
        "value": "web"
      },
      {
        "key": "env",
        "value": "{\"GIT_ALTERNATE_OBJECT_DIRECTORIES\":[],\"GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE\":[],\"GIT_OBJECT_DIRECTORY\":null,\"GIT_OBJECT_DIRECTORY_RELATIVE\":null}"
      },
      {
        "key": "user_id",
        "value": "2"
      },
      {
        "key": "secret_token",
        "value": "[FILTERED]"
      }
    ],
    "host": "gitlab.example.com",
    "ip": "REDACTED",
    "ua": "Ruby",
    "route": "\/api\/:version\/internal\/allowed",
    "queue_duration": 4.24,
    "gitaly_calls": 0,
    "gitaly_duration": 0,
    "correlation_id": "XPUZqTukaP3"
  }

  # nginx_access.log
  [IP] - - [18/Jul/2019:00:30:14 +0000] "POST /api/v4/internal/allowed HTTP/1.1" 401 30 "" "Ruby"
  ```

To fix this problem, confirm that your [`gitlab-secrets.json` file](configure_gitaly.md#configure-gitaly-servers)
on the Gitaly server matches the one on Gitaly client. If it doesn't match,
update the secrets file on the Gitaly server to match the Gitaly client, then
[reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Command line tools cannot connect to Gitaly

gRPC cannot reach your Gitaly server if:

- You can't connect to a Gitaly server with command-line tools.
- Certain actions result in a `14: Connect Failed` error message.

Verify you can reach Gitaly by using TCP:

```shell
sudo gitlab-rake gitlab:tcp_check[GITALY_SERVER_IP,GITALY_LISTEN_PORT]
```

If the TCP connection:

- Fails, check your network settings and your firewall rules.
- Succeeds, your networking and firewall rules are correct.

If you use proxy servers in your command line environment such as Bash, these can interfere with
your gRPC traffic.

If you use Bash or a compatible command line environment, run the following commands to determine
whether you have proxy servers configured:

```shell
echo $http_proxy
echo $https_proxy
```

If either of these variables have a value, your Gitaly CLI connections may be getting routed through
a proxy which cannot connect to Gitaly.

To remove the proxy setting, run the following commands (depending on which variables had values):

```shell
unset http_proxy
unset https_proxy
```

### Permission denied errors appearing in Gitaly or Praefect logs when accessing repositories

You might see the following in Gitaly and Praefect logs:

```shell
{
  ...
  "error":"rpc error: code = PermissionDenied desc = permission denied",
  "grpc.code":"PermissionDenied",
  "grpc.meta.client_name":"gitlab-web",
  "grpc.request.fullMethod":"/gitaly.ServerService/ServerInfo",
  "level":"warning",
  "msg":"finished unary call with code PermissionDenied",
  ...
}
```

This is a GRPC call
[error response code](https://grpc.github.io/grpc/core/md_doc_statuscodes.html).

If this error occurs, even though
[the Gitaly auth tokens are set up correctly](#praefect-errors-in-logs),
it's likely that the Gitaly servers are experiencing
[clock drift](https://en.wikipedia.org/wiki/Clock_drift).

Ensure the Gitaly clients and servers are synchronized, and use an NTP time
server to keep them synchronized.

### Gitaly not listening on new address after reconfiguring

When updating the `gitaly['listen_addr']` or `gitaly['prometheus_listen_addr']` values, Gitaly may
continue to listen on the old address after a `sudo gitlab-ctl reconfigure`.

When this occurs, run `sudo gitlab-ctl restart` to resolve the issue. This should no longer be
necessary because [this issue](https://gitlab.com/gitlab-org/gitaly/-/issues/2521) is resolved.

### Permission denied errors appearing in Gitaly logs when accessing repositories from a standalone Gitaly node

If this error occurs even though file permissions are correct, it's likely that the Gitaly node is
experiencing [clock drift](https://en.wikipedia.org/wiki/Clock_drift).

Please ensure that the GitLab and Gitaly nodes are synchronized and use an NTP time
server to keep them synchronized if possible.

## Troubleshoot Praefect (Gitaly Cluster)

The following sections provide possible solutions to Gitaly Cluster errors.

### Praefect errors in logs

If you receive an error, check `/var/log/gitlab/gitlab-rails/production.log`.

Here are common errors and potential causes:

- 500 response code
  - **ActionView::Template::Error (7:permission denied)**
    - `praefect['auth_token']` and `gitlab_rails['gitaly_token']` do not match on the GitLab server.
  - **Unable to save project. Error: 7:permission denied**
    - Secret token in `praefect['storage_nodes']` on GitLab server does not match the
      value in `gitaly['auth_token']` on one or more Gitaly servers.
- 503 response code
  - **GRPC::Unavailable (14:failed to connect to all addresses)**
    - GitLab was unable to reach Praefect.
  - **GRPC::Unavailable (14:all SubCons are in TransientFailure...)**
    - Praefect cannot reach one or more of its child Gitaly nodes. Try running
      the Praefect connection checker to diagnose.

### Determine primary Gitaly node

To determine the current primary Gitaly node for a specific Praefect node:

- Use the `Shard Primary Election` [Grafana chart](praefect.md#grafana) on the
  [`Gitlab Omnibus - Praefect` dashboard](https://gitlab.com/gitlab-org/grafana-dashboards/-/blob/master/omnibus/praefect.json).
  This is recommended.
- If you do not have Grafana set up, use the following command on each host of each
  Praefect node:

  ```shell
  curl localhost:9652/metrics | grep gitaly_praefect_primaries`
  ```

### Relation does not exist errors

By default Praefect database tables are created automatically by `gitlab-ctl reconfigure` task.

However, the Praefect database tables are not created on initial reconfigure and can throw
errors that relations do not exist if either:

- The `gitlab-ctl reconfigure` command isn't executed.
- There are errors during the execution.

For example:

- `ERROR:  relation "node_status" does not exist at character 13`
- `ERROR:  relation "replication_queue_lock" does not exist at character 40`
- This error:

  ```json
  {"level":"error","msg":"Error updating node: pq: relation \"node_status\" does not exist","pid":210882,"praefectName":"gitlab1x4m:0.0.0.0:2305","time":"2021-04-01T19:26:19.473Z","virtual_storage":"praefect-cluster-1"}
  ```

To solve this, the database schema migration can be done using `sql-migrate` sub-command of
the `praefect` command:

```shell
$ sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-migrate
praefect sql-migrate: OK (applied 21 migrations)
```
