---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Gitaly
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Refer to the information below when troubleshooting Gitaly. For information on troubleshooting Gitaly Cluster (Praefect),
see [Troubleshooting Gitaly Cluster](troubleshooting_gitaly_cluster.md).

The following sections provide possible solutions to Gitaly errors.

See also [Gitaly timeout](../settings/gitaly_timeouts.md) settings,
and our advice on [parsing the `gitaly/current` file](../logs/log_parsing.md#parsing-gitalycurrent).

## Check versions when using standalone Gitaly servers

When using standalone Gitaly servers, you must make sure they are the same version
as GitLab to ensure full compatibility:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Gitaly servers**.
1. Confirm all Gitaly servers indicate that they are up to date.

## Find storage resource details

You can run the following commands in a [Rails console](../operations/rails_console.md#starting-a-rails-console-session)
to determine the available and used space on a Gitaly storage:

```ruby
Gitlab::GitalyClient::ServerService.new("default").storage_disk_statistics
# For Gitaly Cluster
Gitlab::GitalyClient::ServerService.new("<storage name>").disk_statistics
```

## Use `gitaly-debug`

The `gitaly-debug` command provides "production debugging" tools for Gitaly and Git
performance. It is intended to help production engineers and support
engineers investigate Gitaly performance problems.

To see the help page of `gitaly-debug` for a list of supported sub-commands, run:

```shell
gitaly-debug -h
```

## Use `gitaly git` when Git is required for troubleshooting

Use `gitaly git` to execute Git commands by using the same Git execution environment as Gitaly for debugging or
testing purposes. `gitaly git` is the preferred method to ensure version compatibility.

`gitaly git` passes all arguments through to the underlying Git invocation and
supports all forms of input that Git supports. To use `gitaly git`, run:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git <git-command>
```

For example, to run `git ls-tree` through Gitaly on a Linux package instance in the working directory of a repository:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git ls-tree --name-status HEAD
```

## Commits, pushes, and clones return a 401

```plaintext
remote: GitLab: 401 Unauthorized
```

You need to sync your `gitlab-secrets.json` file with your GitLab
application nodes.

## 500 and `fetching folder content` errors on repository pages

`Fetching folder content`, and in some cases `500`, errors indicate
connectivity problems between GitLab and Gitaly.
Consult the [client-side gRPC logs](#client-side-grpc-logs)
for details.

## Client side gRPC logs

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
[known Linux package installation configuration problem](https://docs.gitlab.com/omnibus/settings/ssl/index.html).

If `openssl` succeeds but `gitlab-rake gitlab:gitaly:check` fails,
check [certificate requirements](tls_support.md#certificate-requirements) for Gitaly.

## Server side gRPC logs

gRPC tracing can also be enabled in Gitaly itself with the `GODEBUG=http2debug`
environment variable. To set this in a Linux package installation:

1. Add the following to your `gitlab.rb` file:

   ```ruby
   gitaly['env'] = {
     "GODEBUG=http2debug" => "2"
   }
   ```

1. [Reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab.

## Correlating Git processes with RPCs

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

## Repository changes fail with a `401 Unauthorized` error

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
- Creating a new project and [initializing it with a README](../../user/project/_index.md#create-a-blank-project)
  successfully creates the project but doesn't create the README.
- When [tailing the logs](https://docs.gitlab.com/omnibus/settings/logs.html#tail-logs-in-a-console-on-the-server)
  on a Gitaly client and reproducing the error, you get `401` errors
  when reaching the [`/api/v4/internal/allowed`](../../development/internal_api/_index.md) endpoint:

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
[reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation).

If you've confirmed that your `gitlab-secrets.json` file is the same on all Gitaly servers and clients,
the application might be fetching this secret from a different file. Your Gitaly server's
`config.toml file` indicates the secrets file in use.

## Repository pushes fail with `401 Unauthorized` and `JWT::VerificationError`

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

This combination of errors occurs when the GitLab server has been upgraded to GitLab 15.5 or later but Gitaly has not yet been upgraded.

From GitLab 15.5, GitLab [authenticates with GitLab Shell using a JWT token instead of a shared secret](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86148).
You should follow the [recommendations on upgrading external Gitaly](../../update/_index.md#external-gitaly) and upgrade Gitaly before the GitLab
server.

## Repository pushes fail with a `deny updating a hidden ref` error

Gitaly has read-only, internal GitLab references that users are not permitted to update. If you attempt to update
internal references with `git push --mirror`, Git returns the rejection error, `deny updating a hidden ref`.

The following references are read-only:

- refs/environments/
- refs/keep-around/
- refs/merge-requests/
- refs/pipelines/

To mirror-push branches and tags only, and avoid attempting to mirror-push protected refs, run:

```shell
git push --force-with-lease origin 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'
```

Any other namespaces that the administrator wants to push can be included there as well via
additional [refspecs](https://git-scm.com/docs/git-push#_options).

## Command-line tools cannot connect to Gitaly

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

## Permission denied errors appearing in Gitaly or Praefect logs when accessing repositories

You might see the following in Gitaly and Praefect logs:

```shell
{
  ...
  "error":"rpc error: code = PermissionDenied desc = permission denied: token has expired",
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
[the Gitaly auth tokens are set up correctly](troubleshooting_gitaly_cluster.md#praefect-errors-in-logs),
it's likely that the Gitaly servers are experiencing
[clock drift](https://en.wikipedia.org/wiki/Clock_drift). The auth tokens sent to Gitaly include a timestamp. To be considered valid, Gitaly requires that timestamp to be within 60 seconds of the Gitaly server time.

Ensure the Gitaly clients and servers are synchronized, and use a Network Time Protocol (NTP) time
server to keep them synchronized.

## Gitaly not listening on new address after reconfiguring

When updating the `gitaly['configuration'][:listen_addr]` or `gitaly['configuration'][:prometheus_listen_addr]` values, Gitaly may
continue to listen on the old address after a `sudo gitlab-ctl reconfigure`.

When this occurs, run `sudo gitlab-ctl restart` to resolve the issue. This should no longer be
necessary because [this issue](https://gitlab.com/gitlab-org/gitaly/-/issues/2521) is resolved.

## Health check warnings

The following warning in `/var/log/gitlab/praefect/current` can be ignored.

```plaintext
"error":"full method name not found: /grpc.health.v1.Health/Check",
"msg":"error when looking up method info"
```

## File not found errors

The following errors in `/var/log/gitlab/gitaly/current` can be ignored.
They are caused by the GitLab Rails application checking for specific files
that do not exist in a repository.

```plaintext
"error":"not found: .gitlab/route-map.yml"
"error":"not found: Dockerfile"
"error":"not found: .gitlab-ci.yml"
```

## Git pushes are slow when Dynatrace is enabled

Dynatrace can cause the `sudo -u git -- /opt/gitlab/embedded/bin/gitaly-hooks` reference transaction hook,
to take several seconds to start up and shut down. `gitaly-hooks` is executed twice when users
push, which causes a significant delay.

If Git pushes are too slow when Dynatrace is enabled, disable Dynatrace.

## `gitaly check` fails with `401` status code

`gitaly check` can fail with `401` status code if Gitaly can't access the internal GitLab API.

One way to resolve this is to make sure the entry is correct for the GitLab internal API URL configured in `gitlab.rb` with `gitlab_rails['internal_api_url']`.

## Changes (diffs) don't load for new merge requests when using Gitaly TLS

After enabling [Gitaly with TLS](tls_support.md), changes (diffs) for new merge requests are not generated
and you see the following message in GitLab:

```plaintext
Building your merge request... This page will update when the build is complete
```

Gitaly must be able to connect to itself to complete some operations. If the Gitaly certificate is not trusted by the Gitaly server,
merge request diffs can't be generated.

If Gitaly can't connect to itself, you see messages in the [Gitaly logs](../logs/_index.md#gitaly-logs) like the following messages:

```json
{
   "level":"warning",
   "msg":"[core] [Channel #16 SubChannel #17] grpc: addrConn.createTransport failed to connect to {Addr: \"ext-gitaly.example.com:9999\", ServerName: \"ext-gitaly.example.com:9999\", }. Err: connection error: desc = \"transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
{
   "level":"info",
   "msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: remote error: tls: bad certificate\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
```

To resolve the problem, ensure that you have added your Gitaly certificate to the `/etc/gitlab/trusted-certs` folder on the Gitaly server
and:

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) so the certificates are symlinked
1. Restart Gitaly manually `sudo gitlab-ctl restart gitaly` for the certificates to be loaded by the Gitaly process.

## Gitaly fails to fork processes stored on `noexec` file systems

Applying the `noexec` option to a mount point (for example, `/var`) causes Gitaly to throw `permission denied` errors
related to forking processes. For example:

```shell
fork/exec /var/opt/gitlab/gitaly/run/gitaly-2057/gitaly-git2go: permission denied
```

To resolve this, remove the `noexec` option from the file system mount. An alternative is to change the Gitaly runtime directory:

1. Add `gitaly['runtime_dir'] = '<PATH_WITH_EXEC_PERM>'` to `/etc/gitlab/gitlab.rb` and specify a location without `noexec` set.
1. Run `sudo gitlab-ctl reconfigure`.

## Commit signing fails with `invalid argument` or `invalid data`

If commit signing fails with either of these errors:

- `invalid argument: signing key is encrypted`
- `invalid data: tag byte does not have MSB set`

This error happens because Gitaly commit signing is headless and not associated with a specific user. The GPG signing key must be created without a passphrase, or the passphrase must be removed before export.

## Gitaly logs show errors in `info` messages

Because of a bug [introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6201) in GitLab 16.3, additional entries were written to the
[Gitaly logs](../logs/_index.md#gitaly-logs). These log entries contained `"level":"info"` but the `msg` string appeared to contain an error.

For example:

```json
{"level":"info","msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: EOF\"","pid":6145,"system":"system","time":"2023-12-14T21:20:39.999Z"}
```

The reason for this log entry is that the underlying gRPC library sometimes output verbose transportation logs. These log entries appear to be errors but are, in general,
safe to ignore.

This bug was [fixed](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6513/) in GitLab 16.4.5, 16.5.5, and 16.6.0, which prevents these types of messages from
being written to the Gitaly logs.

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

### Profile Git operations

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/5700) in GitLab 16.9 [with a flag](../feature_flags.md) named `log_git_traces`. Disabled by default.

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../feature_flags.md)
named `log_git_traces`. On GitLab.com, this feature is available but can be configured by GitLab.com administrators only. On GitLab Dedicated, this feature is not available.

You can profile Git operations that Gitaly performs by sending additional information about Git operations to Gitaly logs. With this information, users have more insight
for performance optimization, debugging, and general telemetry collection. For more information, see the [Git Trace2 API reference](https://git-scm.com/docs/api-trace2).

To prevent system overload, the additional information logging is rate limited. If the rate limit is exceeded, traces are skipped. However, after the rate returns to a healthy
state, the traces are processed again automatically. Rate limiting ensures that the system remains stable and avoids any adverse impact because of excessive trace processing.

## Repositories are shown as empty after a GitLab restore

When using `fapolicyd` for increased security, GitLab can report that a restore from a GitLab backup file was successful but:

- Repositories show as empty.
- Creating new files causes an error similar to:

  ```plaintext
  13:commit: commit: starting process [/var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go -log-format json -log-level -correlation-id
  01GP1383JV6JD6MQJBH2E1RT03 -enabled-feature-flags -disabled-feature-flags commit]: fork/exec /var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go: operation not permitted.
  ```

- Gitaly logs might contain errors similar to:

  ```plaintext
   "error": "exit status 128, stderr: \"fatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction':

    Operation not permitted\\nfatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction': Operation
    not permitted\\nfatal: ref updates aborted by hook\\n\"",
   "grpc.code": "Internal",
   "grpc.meta.deadline_type": "none",
   "grpc.meta.method_type": "client_stream",
   "grpc.method": "FetchBundle",
   "grpc.request.fullMethod": "/gitaly.RepositoryService/FetchBundle",
  ...
  ```

You can use
[debug mode](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/assembly_blocking-and-allowing-applications-using-fapolicyd_security-hardening#ref_troubleshooting-problems-related-to-fapolicyd_assembly_blocking-and-allowing-applications-using-fapolicyd)
to help determine if `fapolicyd` is denying execution based on current rules.

If you find that `fapolicyd` is denying execution, consider the following:

1. Allow all executables in `/var/opt/gitlab/gitaly` in your `fapolicyd` configuration:

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. Restart the services:

   ```shell
   sudo systemctl restart fapolicyd

   sudo gitlab-ctl restart gitaly
   ```

## `Pre-receive hook declined` error when pushing to RHEL instance with `fapolicyd` enabled

When pushing to an RHEL-based instance with `fapolicyd` enabled, you might get a `Pre-receive hook declined` error. This error can occur because `fapolicyd` can block the execution
of the Gitaly binary. To resolve this problem, either:

- Disable `fapolicyd`.
- Create an `fapolicyd` rule to permit execution of Gitaly binaries with `fapolicyd` enabled.

To create a rule to allow Gitaly binary execution:

1. Create a file at `/etc/fapolicyd/rules.d/89-gitlab.rules`.
1. Enter the following into the file:

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. Restart the service:

   ```shell
   systemctl restart fapolicyd
   ```

The new rule takes effect after the daemon restarts.

## Update repositories after removing a storage with a duplicate path

> - Rake task `gitlab:gitaly:update_removed_storage_projects` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153008) in GitLab 17.1.

In GitLab 17.0, support for configuring storages with duplicate paths [was removed](https://gitlab.com/gitlab-org/gitaly/-/issues/5598). This can mean that you
must remove duplicate storage configuration from `gitaly` configuration.

WARNING:
Only use this Rake task when the old and new storages share the same disk path on the same Gitaly server. Using the this Rake task in any other situation
causes the repository to become unavailable. Use the [project repository storage moves API](../../api/project_repository_storage_moves.md) to transfer
projects between storages in all other situations.

When removing from the Gitaly configuration a storage that used the same path as another storage,
the projects associated with the old storage must be reassigned to the new one.

For example, you might have configuration similar to the following:

```ruby
gitaly['configuration'] = {
  storage: [
    {
       name: 'default',
       path: '/var/opt/gitlab/git-data/repositories',
    },
    {
       name: 'duplicate-path',
       path: '/var/opt/gitlab/git-data/repositories',
    },
  ],
}
```

If you were removing `duplicate-path` from the configuration, you would run the following
Rake task to associate any projects assigned to it to `default` instead:

::Tabs

:::TabTitle Linux package installations

```shell
sudo gitlab-rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]"
```

:::TabTitle Self-compiled installations

```shell
sudo -u git -H bundle exec rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]" RAILS_ENV=production
```

::EndTabs
