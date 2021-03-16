---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Gitaly

[Gitaly](https://gitlab.com/gitlab-org/gitaly) is the service that provides high-level RPC access to
Git repositories. Without it, no GitLab components can read or write Git data.

In the Gitaly documentation:

- **Gitaly server** refers to any node that runs Gitaly itself.
- **Gitaly client** refers to any node that runs a process that makes requests of the
  Gitaly server. Processes include, but are not limited to:
  - [GitLab Rails application](https://gitlab.com/gitlab-org/gitlab).
  - [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell).
  - [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse).

GitLab end users do not have direct access to Gitaly. Gitaly manages only Git
repository access for GitLab. Other types of GitLab data aren't accessed using Gitaly.

<!-- vale gitlab.FutureTense = NO -->

WARNING:
From GitLab 13.0, Gitaly support for NFS is deprecated. As of GitLab 14.0, NFS-related issues
with Gitaly will no longer be addressed. Upgrade to [Gitaly Cluster](praefect.md) as soon as
possible. Tools to [enable bulk moves](https://gitlab.com/groups/gitlab-org/-/epics/4916)
of projects to Gitaly Cluster are planned.

<!-- vale gitlab.FutureTense = YES -->

## Architecture

The following is a high-level architecture overview of how Gitaly is used.

![Gitaly architecture diagram](img/architecture_v12_4.png)

## Configure Gitaly

Gitaly comes pre-configured with Omnibus GitLab. For more information on customizing your
Gitaly installation, see [Configure Gitaly](configure_gitaly.md).

## Direct Git access bypassing Gitaly

GitLab doesn't advise directly accessing Gitaly repositories stored on disk with
a Git client, because Gitaly is being continuously improved and changed. These
improvements may invalidate assumptions, resulting in performance degradation, instability, and even data loss.

Gitaly has optimizations, such as the
[`info/refs` advertisement cache](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/design_diskcache.md),
that rely on Gitaly controlling and monitoring access to repositories by using the
official gRPC interface. Likewise, Praefect has optimizations, such as fault
tolerance and distributed reads, that depend on the gRPC interface and
database to determine repository state.

For these reasons, **accessing repositories directly is done at your own risk
and is not supported**.

## Direct access to Git in GitLab

Direct access to Git uses code in GitLab known as the "Rugged patches".

### History

Before Gitaly existed, what are now Gitaly clients used to access Git repositories directly, either:

- On a local disk in the case of a single-machine Omnibus GitLab installation
- Using NFS in the case of a horizontally-scaled GitLab installation.

Besides running plain `git` commands, GitLab used to use a Ruby library called
[Rugged](https://github.com/libgit2/rugged). Rugged is a wrapper around
[libgit2](https://libgit2.org/), a stand-alone implementation of Git in the form of a C library.

Over time it became clear that Rugged, particularly in combination with
[Unicorn](https://yhbt.net/unicorn/), is extremely efficient. Because `libgit2` is a library and
not an external process, there was very little overhead between:

- GitLab application code that tried to look up data in Git repositories.
- The Git implementation itself.

Because the combination of Rugged and Unicorn was so efficient, the GitLab application code ended up with lots of
duplicate Git object lookups. For example, looking up the `master` commit a dozen times in one
request. We could write inefficient code without poor performance.

When we migrated these Git lookups to Gitaly calls, we suddenly had a much higher fixed cost per Git
lookup. Even when Gitaly is able to re-use an already-running `git` process (for example, to look up
a commit), you still have:

- The cost of a network roundtrip to Gitaly.
- Inside Gitaly, a write/read roundtrip on the Unix pipes that connect Gitaly to the `git` process.

Using GitLab.com to measure, we reduced the number of Gitaly calls per request until the loss of
Rugged's efficiency was no longer felt. It also helped that we run Gitaly itself directly on the Git
file severs, rather than by using NFS mounts. This gave us a speed boost that counteracted the negative
effect of not using Rugged anymore.

Unfortunately, other deployments of GitLab could not remove NFS like we did on GitLab.com, and they
got the worst of both worlds:

- The slowness of NFS.
- The increased inherent overhead of Gitaly.

The code removed from GitLab during the Gitaly migration project affected these deployments. As a
performance workaround for these NFS-based deployments, we re-introduced some of the old Rugged
code. This re-introduced code is informally referred to as the "Rugged patches".

### How it works

The Ruby methods that perform direct Git access are behind
[feature flags](../../development/gitaly.md#legacy-rugged-code), disabled by default. It wasn't
convenient to set feature flags to get the best performance, so we added an automatic mechanism that
enables direct Git access.

When GitLab calls a function that has a "Rugged patch", it performs two checks:

- Is the feature flag for this patch set in the database? If so, the feature flag setting controls
  the GitLab use of "Rugged patch" code.
- If the feature flag is not set, GitLab tries accessing the file system underneath the
  Gitaly server directly. If it can, it uses the "Rugged patch":
  - If using Unicorn.
  - If using Puma and [thread count](../../install/requirements.md#puma-threads) is set
    to `1`.

The result of these checks is cached.

To see if GitLab can access the repository file system directly, we use the following heuristic:

- Gitaly ensures that the file system has a metadata file in its root with a UUID in it.
- Gitaly reports this UUID to GitLab by using the `ServerInfo` RPC.
- GitLab Rails tries to read the metadata file directly. If it exists, and if the UUID's match,
  assume we have direct access.

Direct Git access is enable by default in Omnibus GitLab because it fills in the correct repository
paths in the GitLab configuration file `config/gitlab.yml`. This satisfies the UUID check.

WARNING:
If directly copying repository data from a GitLab server to Gitaly, ensure that the metadata file,
default path `/var/opt/gitlab/git-data/repositories/.gitaly-metadata`, is not included in the transfer.
Copying this file causes GitLab to use the Rugged patches for repositories hosted on the Gitaly server,
leading to `Error creating pipeline` and `Commit not found` errors, or stale data.

### Transition to Gitaly Cluster

For the sake of removing complexity, we must remove direct Git access in GitLab. However, we can't
remove it as long some GitLab installations require Git repositories on NFS.

There are two facets to our efforts to remove direct Git access in GitLab:

- Reduce the number of inefficient Gitaly queries made by GitLab.
- Persuade administrators of fault-tolerant or horizontally-scaled GitLab instances to migrate off
  NFS.

The second facet presents the only real solution. For this, we developed
[Gitaly Cluster](praefect.md).

## Troubleshooting Gitaly

Check [Gitaly timeouts](../../user/admin_area/settings/gitaly_timeouts.md) when troubleshooting
Gitaly.

### Check versions when using standalone Gitaly servers

When using standalone Gitaly servers, you must make sure they are the same version
as GitLab to ensure full compatibility. Check **Admin Area > Overview > Gitaly Servers** on
your GitLab instance and confirm all Gitaly servers indicate that they are up to date.

### `gitaly-debug`

The `gitaly-debug` command provides "production debugging" tools for Gitaly and Git
performance. It is intended to help production engineers and support
engineers investigate Gitaly performance problems.

If you're using GitLab 11.6 or newer, this tool should be installed on
your GitLab / Gitaly server already at `/opt/gitlab/embedded/bin/gitaly-debug`.
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

You need to sync your `gitlab-secrets.json` file with your Gitaly clients (GitLab
app nodes).

### Client side gRPC logs

Gitaly uses the [gRPC](https://grpc.io/) RPC framework. The Ruby gRPC
client has its own log file which may contain debugging information when
you are seeing Gitaly errors. You can control the log level of the
gRPC client with the `GRPC_LOG_LEVEL` environment variable. The
default level is `WARN`.

You can run a gRPC trace with:

```shell
sudo GRPC_TRACE=all GRPC_VERBOSITY=DEBUG gitlab-rake gitlab:gitaly:check
```

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
querying `grpc_client_handled_total`. Strictly speaking, this metric does
not differentiate between `gitaly-ruby` and other RPCs, but in practice
(as of GitLab 11.9), all gRPC calls made by Gitaly itself are internal
calls from the main Gitaly process to one of its `gitaly-ruby` sidecars.

Assuming your `grpc_client_handled_total` counter observes only Gitaly,
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
  successfully creates the project, but doesn't create the README.
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

If you can't connect to a Gitaly server with command line (CLI) tools,
and certain actions result in a `14: Connect Failed` error message,
gRPC cannot reach your Gitaly server.

Verify you can reach Gitaly by using TCP:

```shell
sudo gitlab-rake gitlab:tcp_check[GITALY_SERVER_IP,GITALY_LISTEN_PORT]
```

If the TCP connection fails, check your network settings and your firewall rules.
If the TCP connection succeeds, your networking and firewall rules are correct.

If you use proxy servers in your command line environment, such as Bash, these
can interfere with your gRPC traffic.

If you use Bash or a compatible command line environment, run the following commands
to determine whether you have proxy servers configured:

```shell
echo $http_proxy
echo $https_proxy
```

If either of these variables have a value, your Gitaly CLI connections may be
getting routed through a proxy which cannot connect to Gitaly.

To remove the proxy setting, run the following commands (depending on which variables had values):

```shell
unset http_proxy
unset https_proxy
```

### Permission denied errors appearing in Gitaly logs when accessing repositories from a standalone Gitaly server

If this error occurs even though file permissions are correct, it's likely that
the Gitaly server is experiencing
[clock drift](https://en.wikipedia.org/wiki/Clock_drift).

Ensure the Gitaly clients and servers are synchronized, and use an NTP time
server to keep them synchronized, if possible.

### Praefect

Praefect is a router and transaction manager for Gitaly, and a required
component for running a Gitaly Cluster. For more information see [Gitaly Cluster](praefect.md).
