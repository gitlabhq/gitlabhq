---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Gitaly and Gitaly Cluster **(FREE SELF)**

Refer to the information below when troubleshooting Gitaly and Gitaly Cluster.

## Troubleshoot Gitaly

The following sections provide possible solutions to Gitaly errors.

See also [Gitaly timeout](../../user/admin_area/settings/gitaly_timeouts.md) settings,
and our advice on [parsing the `gitaly/current` file](../logs/log_parsing.md#parsing-gitalycurrent).

### Check versions when using standalone Gitaly servers

When using standalone Gitaly servers, you must make sure they are the same version
as GitLab to ensure full compatibility:

1. On the top bar, select **Main menu > Admin** on your GitLab instance.
1. On the left sidebar, select **Overview > Gitaly Servers**.
1. Confirm all Gitaly servers indicate that they are up to date.

### Find storage resource details

You can run the following commands in a [Rails console](../operations/rails_console.md#starting-a-rails-console-session)
to determine the available and used space on a Gitaly storage:

```ruby
Gitlab::GitalyClient::ServerService.new("default").storage_disk_statistics
# For Gitaly Cluster
Gitlab::GitalyClient::ServerService.new("<storage name>").disk_statistics
```

### Use `gitaly-debug`

The `gitaly-debug` command provides "production debugging" tools for Gitaly and Git
performance. It is intended to help production engineers and support
engineers investigate Gitaly performance problems.

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

### 500 and `fetching folder content` errors on repository pages

`Fetching folder content`, and in some cases `500`, errors indicate
connectivity problems between GitLab and Gitaly.
Consult the [client-side gRPC logs](#client-side-grpc-logs)
for details.

### Client side gRPC logs

Gitaly uses the [gRPC](https://grpc.io/) RPC framework. The Ruby gRPC
client has its own log file which may contain helpful information when
you are seeing Gitaly errors. You can control the log level of the
gRPC client with the `GRPC_LOG_LEVEL` environment variable. The
default level is `WARN`.

You can run a gRPC trace with:

```shell
sudo GRPC_TRACE=all GRPC_VERBOSITY=DEBUG gitlab-rake gitlab:gitaly:check
```

If this command fails with a `failed to connect to all addresses` error,
check for an SSL or TLS problem:

```shell
/opt/gitlab/embedded/bin/openssl s_client -connect <gitaly-ipaddress>:<port> -verify_return_error
```

Check whether `Verify return code` field indicates a
[known Omnibus GitLab configuration problem](https://docs.gitlab.com/omnibus/settings/ssl/index.html).

If `openssl` succeeds but `gitlab-rake gitlab:gitaly:check` fails,
check [certificate requirements](configure_gitaly.md#certificate-requirements) for Gitaly.

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
- Creating a new project and [initializing it with a README](../../user/project/index.md#create-a-blank-project)
  successfully creates the project but doesn't create the README.
- When [tailing the logs](https://docs.gitlab.com/omnibus/settings/logs.html#tail-logs-in-a-console-on-the-server)
  on a Gitaly client and reproducing the error, you get `401` errors
  when reaching the [`/api/v4/internal/allowed`](../../development/internal_api/index.md) endpoint:

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

If you've confirmed that your `gitlab-secrets.json` file is the same on all Gitaly servers and clients,
the application might be fetching this secret from a different file. Your Gitaly server's
`config.toml file` indicates the secrets file in use.
If that setting is missing, GitLab defaults to using `.gitlab_shell_secret` under
`/opt/gitlab/embedded/service/gitlab-rails/.gitlab_shell_secret`.

### Repository pushes fail

When attempting `git push`, you can see:

- `401 Unauthorized` errors.
- The following in server logs:

  ```json
  {
    ...
    "exception.class":"JWT::VerificationError",
    "exception.message":"Signature verification raised",
    ...
  }
  ```

This error occurs when the GitLab server has been upgraded to GitLab 15.5 or later but Gitaly has not yet been upgraded.

From GitLab 15.5, GitLab [authenticates with GitLab Shell using a JWT token instead of a shared secret](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86148).
You should follow the [recommendations on upgrading external Gitaly](../../update/plan_your_upgrade.md#external-gitaly) and upgrade Gitaly before the GitLab
server.

### Repository pushes fail with a `deny updating a hidden ref` error

Due to [a change](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/3426)
introduced in GitLab 13.12, Gitaly has read-only, internal GitLab references that users are not
permitted to update. If you attempt to update internal references with `git push --mirror`, Git
returns the rejection error, `deny updating a hidden ref`.

The following references are read-only:

- refs/environments/
- refs/keep-around/
- refs/merge-requests/
- refs/pipelines/

To mirror-push branches and tags only, and avoid attempting to mirror-push protected refs, run:

```shell
git push origin +refs/heads/*:refs/heads/* +refs/tags/*:refs/tags/*
```

Any other namespaces that the administrator wants to push can be included there as well via additional patterns.

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

This information in the logs is a gRPC call
[error response code](https://grpc.github.io/grpc/core/md_doc_statuscodes.html).

If this error occurs, even though
[the Gitaly auth tokens are set up correctly](#praefect-errors-in-logs),
it's likely that the Gitaly servers are experiencing
[clock drift](https://en.wikipedia.org/wiki/Clock_drift).

Ensure the Gitaly clients and servers are synchronized, and use an NTP time
server to keep them synchronized.

### Gitaly not listening on new address after reconfiguring

When updating the `gitaly['configuration'][:listen_addr]` or `gitaly['configuration'][:prometheus_listen_addr]` values, Gitaly may
continue to listen on the old address after a `sudo gitlab-ctl reconfigure`.

When this occurs, run `sudo gitlab-ctl restart` to resolve the issue. This should no longer be
necessary because [this issue](https://gitlab.com/gitlab-org/gitaly/-/issues/2521) is resolved.

### Permission denied errors appearing in Gitaly logs when accessing repositories from a standalone Gitaly node

If this error occurs even though file permissions are correct, it's likely that the Gitaly node is
experiencing [clock drift](https://en.wikipedia.org/wiki/Clock_drift).

Ensure that the GitLab and Gitaly nodes are synchronized and use an NTP time
server to keep them synchronized if possible.

### Health check warnings

The following warning in `/var/log/gitlab/praefect/current` can be ignored.

```plaintext
"error":"full method name not found: /grpc.health.v1.Health/Check",
"msg":"error when looking up method info"
```

### File not found errors

The following errors in `/var/log/gitlab/gitaly/current` can be ignored.
They are caused by the GitLab Rails application checking for specific files
that do not exist in a repository.

```plaintext
"error":"not found: .gitlab/route-map.yml"
"error":"not found: Dockerfile"
"error":"not found: .gitlab-ci.yml"
```

### Git pushes are slow when Dynatrace is enabled

Dynatrace can cause the `/opt/gitlab/embedded/bin/gitaly-hooks` reference transaction hook,
to take several seconds to start up and shut down. `gitaly-hooks` is executed twice when users
push, which causes a significant delay.

If Git pushes are too slow when Dynatrace is enabled, disable Dynatrace.

### `gitaly check` fails with `401` status code

`gitaly check` can fail with `401` status code if Gitaly can't access the internal GitLab API.

One way to resolve this is to make sure the entry is correct for the GitLab internal API URL configured in `gitlab.rb` with `gitlab_rails['internal_api_url']`.

## Gitaly fails to fork processes stored on `noexec` file systems

Because of changes [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5999) in GitLab 14.10, applying the `noexec` option to a mount
point (for example, `/var`) causes Gitaly to throw `permission denied` errors related to forking processes. For example:

```shell
fork/exec /var/opt/gitlab/gitaly/run/gitaly-2057/gitaly-git2go: permission denied
```

To resolve this, remove the `noexec` option from the file system mount. An alternative is to change the Gitaly runtime directory:

1. Add `gitaly['runtime_dir'] = '<PATH_WITH_EXEC_PERM>'` to `/etc/gitlab/gitlab.rb` and specify a location without `noexec` set.
1. Run `sudo gitlab-ctl reconfigure`.

## Troubleshoot Praefect (Gitaly Cluster)

The following sections provide possible solutions to Gitaly Cluster errors.

### Check cluster health

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5688) in GitLab 14.5.

The `check` Praefect sub-command runs a series of checks to determine the health of the Gitaly Cluster.

```shell
gitlab-ctl praefect check
```

The following sections describe the checks that are run.

#### Praefect migrations

Because Database migrations must be up to date for Praefect to work correctly, checks if Praefect migrations are up to date.

If this check fails:

1. See the `schema_migrations` table in the database to see which migrations have run.
1. Run `praefect sql-migrate` to bring the migrations up to date.

#### Node connectivity and disk access

Checks if Praefect can reach all of its Gitaly nodes, and if each Gitaly node has read and write access to all of its storages.

If this check fails:

1. Confirm the network addresses and tokens are set up correctly:
   - In the Praefect configuration.
   - In each Gitaly node's configuration.
1. On the Gitaly nodes, check that the `gitaly` process being run as `git`. There might be a permissions issue that is preventing Gitaly from
   accessing its storage directories.
1. Confirm that there are no issues with the network that connects Praefect to Gitaly nodes.

#### Database read and write access

Checks if Praefect can read from and write to the database.

If this check fails:

1. See if the Praefect database is in recovery mode. In recovery mode, tables may be read only. To check, run:

   ```sql
   select pg_is_in_recovery()
   ```

1. Confirm that the user that Praefect uses to connect to PostgreSQL has read and write access to the database.
1. See if the database has been placed into read-only mode. To check, run:

   ```sql
   show default_transaction_read_only
   ```

#### Inaccessible repositories

Checks how many repositories are inaccessible because they are missing a primary assignment, or their primary is unavailable.

If this check fails:

1. See if any Gitaly nodes are down. Run `praefect ping-nodes` to check.
1. Check if there is a high load on the Praefect database. If the Praefect database is slow to respond, it can lead health checks failing to persist
   to the database, leading Praefect to think nodes are unhealthy.

#### Check clock synchronization

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/4225) in GitLab 14.8.

Authentication between Praefect and the Gitaly servers requires the server times to be
in sync so the token check succeeds.

This check helps identify the root cause of `permission denied`
[errors being logged by Praefect](#permission-denied-errors-appearing-in-gitaly-or-praefect-logs-when-accessing-repositories).

For offline environments where access to public `pool.ntp.org` servers is not possible, the Praefect `check` sub-command fails this
check with an error message similar to:

```plaintext
checking with NTP service at  and allowed clock drift 60000ms [correlation_id: <XXX>]
Failed (fatal) error: gitaly node at tcp://[gitlab.example-instance.com]:8075: rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

To resolve this issue, set an environment variable on all Praefect servers to point to an accessible internal NTP server. For example:

```shell
export NTP_HOST=ntp.example.com
```

### Praefect errors in logs

If you receive an error, check `/var/log/gitlab/gitlab-rails/production.log`.

Here are common errors and potential causes:

- 500 response code
  - `ActionView::Template::Error (7:permission denied)`
    - `praefect['configuration'][:auth][:token]` and `gitlab_rails['gitaly_token']` do not match on the GitLab server.
  - `Unable to save project. Error: 7:permission denied`
    - Secret token in `praefect['configuration'][:virtual_storage]` on GitLab server does not match the
      value in `gitaly['auth_token']` on one or more Gitaly servers.
- 503 response code
  - `GRPC::Unavailable (14:failed to connect to all addresses)`
    - GitLab was unable to reach Praefect.
  - `GRPC::Unavailable (14:all SubCons are in TransientFailure...)`
    - Praefect cannot reach one or more of its child Gitaly nodes. Try running
      the Praefect connection checker to diagnose.

### Praefect database experiencing high CPU load

Some common reasons for the Praefect database to experience elevated CPU usage include:

- Prometheus metrics scrapes [running an expensive query](https://gitlab.com/gitlab-org/gitaly/-/issues/3796). If you have GitLab 14.2
  or above, set `praefect['configuration'][:prometheus_exclude_database_from_default_metrics] = true` in `gitlab.rb`.
- [Read distribution caching](praefect.md#reads-distribution-caching) is disabled, increasing the number of queries made to the
  database when user traffic is high. Ensure read distribution caching is enabled.

### Determine primary Gitaly node

To determine the primary node of a repository:

- In GitLab 14.6 and later, use the [`praefect metadata`](#view-repository-metadata) subcommand.
- In GitLab 13.12 to GitLab 14.5 with [repository-specific primaries](praefect.md#repository-specific-primary-nodes),
  use the [`gitlab:praefect:replicas` Rake task](../raketasks/praefect.md#replica-checksums).
- With legacy election strategies in GitLab 13.12 and earlier, the primary was the same for all repositories in a virtual storage.
  To determine the current primary Gitaly node for a specific virtual storage:

  - (Recommended) Use the `Shard Primary Election` [Grafana chart](praefect.md#grafana) on the
    [`Gitlab Omnibus - Praefect` dashboard](https://gitlab.com/gitlab-org/grafana-dashboards/-/blob/master/omnibus/praefect.json).
  - If you do not have Grafana set up, use the following command on each host of each
    Praefect node:

    ```shell
    curl localhost:9652/metrics | grep gitaly_praefect_primaries`
    ```

### View repository metadata

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/3481) in GitLab 14.6.

Gitaly Cluster maintains a [metadata database](index.md#components) about the repositories stored on the cluster. Use the `praefect metadata` subcommand
to inspect the metadata for troubleshooting.

You can retrieve a repository's metadata by its Praefect-assigned repository ID:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id <repository-id>
```

You can also retrieve a repository's metadata by its virtual storage and relative path:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage <virtual-storage> -relative-path <relative-path>
```

#### Examples

To retrieve the metadata for a repository with a Praefect-assigned repository ID of 1:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id 1
```

To retrieve the metadata for a repository with virtual storage `default` and relative path `@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage default -relative-path @hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git
```

Either of these examples retrieve the following metadata for an example repository:

```plaintext
Repository ID: 54771
Virtual Storage: "default"
Relative Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Replica Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Primary: "gitaly-1"
Generation: 1
Replicas:
- Storage: "gitaly-1"
  Assigned: true
  Generation: 1, fully up to date
  Healthy: true
  Valid Primary: true
  Verified At: 2021-04-01 10:04:20 +0000 UTC
- Storage: "gitaly-2"
  Assigned: true
  Generation: 0, behind by 1 changes
  Healthy: true
  Valid Primary: false
  Verified At: unverified
- Storage: "gitaly-3"
  Assigned: true
  Generation: replica not yet created
  Healthy: false
  Valid Primary: false
  Verified At: unverified
```

#### Available metadata

The metadata retrieved by `praefect metadata` includes the fields in the following tables.

| Field             | Description                                                                                                        |
|:------------------|:-------------------------------------------------------------------------------------------------------------------|
| `Repository ID`   | Permanent unique ID assigned to the repository by Praefect. Different to the ID GitLab uses for repositories.      |
| `Virtual Storage` | Name of the virtual storage the repository is stored in.                                                           |
| `Relative Path`   | Repository's path in the virtual storage.                                                                          |
| `Replica Path`    | Where on the Gitaly node's disk the repository's replicas are stored.                                                |
| `Primary`         | Current primary of the repository.                                                                                 |
| `Generation`      | Used by Praefect to track repository changes. Each write in the repository increments the repository's generation. |
| `Replicas`        | A list of replicas that exist or are expected to exist.                                                            |

For each replica, the following metadata is available:

| `Replicas` Field | Description                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|:-----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Storage`        | Name of the Gitaly storage that contains the replica.                                                                                                                                                                                                                                                                                                                                                                                                  |
| `Assigned`       | Indicates whether the replica is expected to exist in the storage. Can be `false` if a Gitaly node is removed from the cluster or if the storage contains an extra copy after the repository's replication factor was decreased.                                                                                                                                                                                                                       |
| `Generation`     | Latest confirmed generation of the replica. It indicates:<br><br>- The replica is fully up to date if the generation matches the repository's generation.<br>- The replica is outdated if the replica's generation is less than the repository's generation.<br>- `replica not yet created` if the replica does not yet exist at all on the storage.                                                                                                          |
| `Healthy`        | Indicates whether the Gitaly node that is hosting this replica is considered healthy by the consensus of Praefect nodes.                                                                                                                                                                                                                                                                                                                               |
| `Valid Primary`  | Indicates whether the replica is fit to serve as the primary node. If the repository's primary is not a valid primary, a failover occurs on the next write to the repository if there is another replica that is a valid primary. A replica is a valid primary if:<br><br>- It is stored on a healthy Gitaly node.<br>- It is fully up to date.<br>- It is not targeted by a pending deletion job from decreasing replication factor.<br>- It is assigned. |
| `Verified At` | Indicates last successful verification of the replica by the [verification worker](praefect.md#repository-verification). If the replica has not yet been verified, `unverified` is displayed in place of the last successful verification time. Introduced in GitLab 15.0. |

#### Command fails with 'repository not found'

If the supplied value for `-virtual-storage` is incorrect, the command returns the following error:

```plaintext
get metadata: rpc error: code = NotFound desc = repository not found
```

The documented examples specify `-virtual-storage default`. Check the Praefect server setting `praefect['configuration'][:virtual_storage]` in `/etc/gitlab/gitlab.rb`.

### Check that repositories are in sync

Is [some cases](index.md#known-issues) the Praefect database can get out of sync with the underlying Gitaly nodes. To check that
a given repository is fully synced on all nodes, run the [`gitlab:praefect:replicas` Rake task](../raketasks/praefect.md#replica-checksums)
that checksums the repository on all Gitaly nodes.

The [Praefect `dataloss`](recovery.md#check-for-data-loss) command only checks the state of the repository in the Praefect database, and cannot
be relied to detect sync problems in this scenario.

### Relation does not exist errors

By default Praefect database tables are created automatically by `gitlab-ctl reconfigure` task.

However, the Praefect database tables are not created on initial reconfigure and can throw
errors that relations do not exist if either:

- The `gitlab-ctl reconfigure` command isn't executed.
- Errors occur during the execution.

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

### Requests fail with 'repository scoped: invalid Repository' errors

This indicates that the virtual storage name used in the
[Praefect configuration](praefect.md#praefect) does not match the storage name used in
[`gitaly['configuration'][:storage][<index>][:name]` setting](praefect.md#gitaly) for GitLab.

Resolve this by matching the virtual storage names used in Praefect and GitLab configuration.

### Gitaly Cluster performance issues on cloud platforms

Praefect does not require a lot of CPU or memory, and can run on small virtual machines.
Cloud services may place other limits on the resources that small VMs can use, such as
disk IO and network traffic.

Praefect nodes generate a lot of network traffic. The following symptoms can be observed if their network bandwidth has
been throttled by the cloud service:

- Poor performance of Git operations.
- High network latency.
- High memory use by Praefect.

Possible solutions:

- Provision larger VMs to gain access to larger network traffic allowances.
- Use your cloud service's monitoring and logging to check that the Praefect nodes are not exhausting their traffic allowances.

### `gitlab-ctl reconfigure` fails with error: `STDOUT: praefect: configuration error: error reading config file: toml: cannot store TOML string into a Go int`

This error occurs when `praefect['database_port']` or `praefect['database_direct_port']` are configured as a string instead of an integer.

## Profiling Gitaly

Gitaly exposes several of the Go built-in performance profiling tools on the Prometheus listen port. For example, if Prometheus is listening
on port `9236` of the GitLab server:

- Get a list of running `goroutines` and their backtraces:

  ```shell
  curl --output goroutines.txt "http://<gitaly_server>:9236/debug/pprof/goroutine?debug=2"
  ```

- Run a CPU profile for 30 seconds:

  ```shell
  curl --output cpu.bin "http://<gitaly_server>:9236/debug/pprof/profile"
  ```

- Profile heap memory usage:

  ```shell
  curl --output heap.bin "http://<gitaly_server>:9236/debug/pprof/heap"
  ```

- Record a 5 second execution trace. This impacts the Gitaly performance while running:

  ```shell
  curl --output trace.bin "http://<gitaly_server>:9236/debug/pprof/trace?seconds=5"
  ```

On a host with `go` installed, the CPU profile and heap profile can be viewed in a browser:

```shell
go tool pprof -http=:8001 cpu.bin
go tool pprof -http=:8001 heap.bin
```

Execution traces can be viewed by running:

```shell
go tool trace heap.bin
```
