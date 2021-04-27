---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting a reference architecture setup **(FREE SELF)**

This page serves as the troubleshooting documentation if you followed one of
the [reference architectures](index.md#reference-architectures).

## Troubleshooting object storage

### S3 API compatibility issues

Not all S3 providers [are fully compatible](../../raketasks/backup_restore.md#other-s3-providers)
with the Fog library that GitLab uses. Symptoms include:

```plaintext
411 Length Required
```

### GitLab Pages requires NFS

If you intend to use [GitLab Pages](../../user/project/pages/index.md), this currently requires
[NFS](../nfs.md). There is [work in progress](https://gitlab.com/groups/gitlab-org/-/epics/3901)
to remove this dependency. In the future, GitLab Pages will use
object storage.

The dependency on disk storage also prevents Pages being deployed using the
[GitLab Helm chart](https://gitlab.com/groups/gitlab-org/-/epics/4283).

### Incremental logging is required for CI to use object storage

If you configure GitLab to use object storage for CI logs and artifacts,
[you must also enable incremental logging](../job_logs.md#incremental-logging-architecture).

### Proxy Download

A number of the use cases for object storage allow client traffic to be redirected to the
object storage back end, like when Git clients request large files via LFS or when
downloading CI artifacts and logs.

When the files are stored on local block storage or NFS, GitLab has to act as a proxy.
With object storage, the default behavior is for GitLab to redirect to the object
storage device rather than proxy the request.

The `proxy_download` setting controls this behavior: the default is generally `false`.
Verify this in the documentation for each use case. Set it to `true` to make
GitLab proxy the files rather than redirect.

When not proxying files, GitLab returns an
[HTTP 302 redirect with a pre-signed, time-limited object storage URL](https://gitlab.com/gitlab-org/gitlab/-/issues/32117#note_218532298).
This can result in some of the following problems:

- If GitLab is using non-secure HTTP to access the object storage, clients may generate
`https->http` downgrade errors and refuse to process the redirect. The solution to this
is for GitLab to use HTTPS. LFS, for example, will generate this error:

   ```plaintext
   LFS: lfsapi/client: refusing insecure redirect, https->http
   ```

- Clients will need to trust the certificate authority that issued the object storage
certificate, or may return common TLS errors such as:

   ```plaintext
   x509: certificate signed by unknown authority
   ```

- Clients will need network access to the object storage. Errors that might result
if this access is not in place include:

   ```plaintext
   Received status code 403 from server: Forbidden
   ```

### ETag mismatch

Using the default GitLab settings, some object storage back-ends such as
[MinIO](https://gitlab.com/gitlab-org/gitlab/-/issues/23188)
and [Alibaba](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564)
might generate `ETag mismatch` errors.

When using GitLab direct upload, the
[workaround for MinIO](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564#note_244497658)
is to use the `--compat` parameter on the server.

We are working on a fix to GitLab component Workhorse, and also
a workaround, in the mean time, to
[allow ETag verification to be disabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18175).

## Troubleshooting Redis

There are a lot of moving parts that needs to be taken care carefully
in order for the HA setup to work as expected.

Before proceeding with the troubleshooting below, check your firewall rules:

- Redis machines
  - Accept TCP connection in `6379`
  - Connect to the other Redis machines via TCP in `6379`
- Sentinel machines
  - Accept TCP connection in `26379`
  - Connect to other Sentinel machines via TCP in `26379`
  - Connect to the Redis machines via TCP in `6379`

### Troubleshooting Redis replication

You can check if everything is correct by connecting to each server using
`redis-cli` application, and sending the `info replication` command as below.

```shell
/opt/gitlab/embedded/bin/redis-cli -h <redis-host-or-ip> -a '<redis-password>' info replication
```

When connected to a `Primary` Redis, you will see the number of connected
`replicas`, and a list of each with connection details:

```plaintext
# Replication
role:master
connected_replicas:1
replica0:ip=10.133.5.21,port=6379,state=online,offset=208037514,lag=1
master_repl_offset:208037658
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:206989083
repl_backlog_histlen:1048576
```

When it's a `replica`, you will see details of the primary connection and if
its `up` or `down`:

```plaintext
# Replication
role:replica
master_host:10.133.1.58
master_port:6379
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
replica_repl_offset:208096498
replica_priority:100
replica_read_only:1
connected_replicas:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

### Troubleshooting Sentinel

If you get an error like: `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this issue](https://github.com/redis/redis-rb/issues/531).

You must make sure you are defining the same value in `redis['master_name']`
and `redis['master_pasword']` as you defined for your sentinel node.

The way the Redis connector `redis-rb` works with sentinel is a bit
non-intuitive. We try to hide the complexity in omnibus, but it still requires
a few extra configurations.

---

To make sure your configuration is correct:

1. SSH into your GitLab application server
1. Enter the Rails console:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For source installations
   sudo -u git rails console -e production
   ```

1. Run in the console:

   ```ruby
   redis = Redis.new(Gitlab::Redis::SharedState.params)
   redis.info
   ```

   Keep this screen open and try to simulate a failover below.

1. To simulate a failover on primary Redis, SSH into the Redis server and run:

   ```shell
   # port must match your primary redis port, and the sleep time must be a few seconds bigger than defined one
    redis-cli -h localhost -p 6379 DEBUG sleep 20
   ```

1. Then back in the Rails console from the first step, run:

   ```ruby
   redis.info
   ```

   You should see a different port after a few seconds delay
   (the failover/reconnect time).

## Troubleshooting Gitaly

If you have any problems when using standalone Gitaly nodes, first
[check all the versions are up to date](../gitaly/index.md#check-versions-when-using-standalone-gitaly-servers).

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

You will need to sync your `gitlab-secrets.json` file with your GitLab
app nodes.

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

### Observing `gitaly-ruby` traffic

[`gitaly-ruby`](../gitaly/configure_gitaly.md#gitaly-ruby) is an internal implementation detail of Gitaly,
so, there's not that much visibility into what goes on inside
`gitaly-ruby` processes.

If you have Prometheus set up to scrape your Gitaly process, you can see
request rates and error codes for individual RPCs in `gitaly-ruby` by
querying `grpc_client_handled_total`. Strictly speaking, this metric does
not differentiate between `gitaly-ruby` and other RPCs, but in practice
(as of GitLab 11.9), all gRPC calls made by Gitaly itself are internal
calls from the main Gitaly process to one of its `gitaly-ruby` sidecars.

Assuming your `grpc_client_handled_total` counter only observes Gitaly,
the following query shows you RPCs are (most likely) internally
implemented as calls to `gitaly-ruby`:

```prometheus
sum(rate(grpc_client_handled_total[5m])) by (grpc_method) > 0
```

### Repository changes fail with a `401 Unauthorized` error

If you're running Gitaly on its own server and notice that users can
successfully clone and fetch repositories (via both SSH and HTTPS), but can't
push to them or make changes to the repository in the web UI without getting a
`401 Unauthorized` message, then it's possible Gitaly is failing to authenticate
with the other nodes due to having the wrong secrets file.

Confirm the following are all true:

- When any user performs a `git push` to any repository on this Gitaly node, it
  fails with the following error (note the `401 Unauthorized`):

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
- When [tailing the logs](https://docs.gitlab.com/omnibus/settings/logs.html#tail-logs-in-a-console-on-the-server) on an app node and reproducing the error, you get `401` errors
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

To fix this problem, confirm that your `gitlab-secrets.json` file
on the Gitaly node matches the one on all other nodes. If it doesn't match,
update the secrets file on the Gitaly node to match the others, then
[reconfigure the node](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Command line tools cannot connect to Gitaly

If you are having trouble connecting to a Gitaly node with command line (CLI) tools, and certain actions result in a `14: Connect Failed` error message, it means that gRPC cannot reach your Gitaly node.

Verify that you can reach Gitaly via TCP:

```shell
sudo gitlab-rake gitlab:tcp_check[GITALY_SERVER_IP,GITALY_LISTEN_PORT]
```

If the TCP connection fails, check your network settings and your firewall rules. If the TCP connection succeeds, your networking and firewall rules are correct.

If you use proxy servers in your command line environment, such as Bash, these can interfere with your gRPC traffic.

If you use Bash or a compatible command line environment, run the following commands to determine whether you have proxy servers configured:

```shell
echo $http_proxy
echo $https_proxy
```

If either of these variables have a value, your Gitaly CLI connections may be getting routed through a proxy which cannot connect to Gitaly.

To remove the proxy setting, run the following commands (depending on which variables had values):

```shell
unset http_proxy
unset https_proxy
```

### Gitaly not listening on new address after reconfiguring

When updating the `gitaly['listen_addr']` or `gitaly['prometheus_listen_addr']` values, Gitaly may continue to listen on the old address after a `sudo gitlab-ctl reconfigure`.

When this occurs, performing a `sudo gitlab-ctl restart` will resolve the issue. This will no longer be necessary after [this issue](https://gitlab.com/gitlab-org/gitaly/-/issues/2521) is resolved.

### Permission denied errors appearing in Gitaly logs when accessing repositories from a standalone Gitaly node

If this error occurs even though file permissions are correct, it's likely that
the Gitaly node is experiencing
[clock drift](https://en.wikipedia.org/wiki/Clock_drift).

Please ensure that the GitLab and Gitaly nodes are synchronized and use an NTP time
server to keep them synchronized if possible.

## Troubleshooting the GitLab Rails application

- `mount: wrong fs type, bad option, bad superblock on`

You have not installed the necessary NFS client utilities. See step 1 above.

- `mount: mount point /var/opt/gitlab/... does not exist`

This particular directory does not exist on the NFS server. Ensure
the share is exported and exists on the NFS server and try to remount.

## Troubleshooting Monitoring

If the monitoring node is not receiving any data, check that the exporters are
capturing data.

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/metric"
```

or

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/-/metric"
```

## Troubleshooting PgBouncer

In case you are experiencing any issues connecting through PgBouncer, the first place to check is always the logs:

```shell
sudo gitlab-ctl tail pgbouncer
```

Additionally, you can check the output from `show databases` in the [administrative console](#pgbouncer-administrative-console). In the output, you would expect to see values in the `host` field for the `gitlabhq_production` database. Additionally, `current_connections` should be greater than 1.

### PgBouncer administrative console

As part of Omnibus GitLab, the `gitlab-ctl pgb-console` command is provided to automatically connect to the PgBouncer administrative console. See the [PgBouncer documentation](https://www.pgbouncer.org/usage.html#admin-console) for detailed instructions on how to interact with the console.

To start a session:

```shell
sudo gitlab-ctl pgb-console
```

The password you will be prompted for is the `pgbouncer_user_password`

To get some basic information about the instance, run

```shell
pgbouncer=# show databases; show clients; show servers;
        name         |   host    | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
---------------------+-----------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
 gitlabhq_production | 127.0.0.1 | 5432 | gitlabhq_production |            |       100 |            5 |           |               0 |                   1
 pgbouncer           |           | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
(2 rows)

 type |   user    |      database       | state  |   addr    | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link
| remote_pid | tls
------+-----------+---------------------+--------+-----------+-------+------------+------------+---------------------+---------------------+-----------+------
+------------+-----
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44590 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12444c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44592 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12447c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44594 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x1244940 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44706 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:16:31 | 0x1244ac0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44708 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:15:15 | 0x1244c40 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44794 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:15:15 | 0x1244dc0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44798 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:16:31 | 0x1244f40 |
|          0 |
 C    | pgbouncer | pgbouncer           | active | 127.0.0.1 | 44660 | 127.0.0.1  |       6432 | 2018-04-24 22:13:51 | 2018-04-24 22:17:12 | 0x1244640 |
|          0 |
(8 rows)

 type |  user  |      database       | state |   addr    | port | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link | rem
ote_pid | tls
------+--------+---------------------+-------+-----------+------+------------+------------+---------------------+---------------------+-----------+------+----
--------+-----
 S    | gitlab | gitlabhq_production | idle  | 127.0.0.1 | 5432 | 127.0.0.1  |      35646 | 2018-04-24 22:15:15 | 2018-04-24 22:17:10 | 0x124dca0 |      |
  19980 |
(1 row)
```

### Message: `LOG:  invalid CIDR mask in address`

See the suggested fix [in Geo documentation](../geo/replication/troubleshooting.md#message-log--invalid-cidr-mask-in-address).

### Message: `LOG:  invalid IP mask "md5": Name or service not known`

See the suggested fix [in Geo documentation](../geo/replication/troubleshooting.md#message-log--invalid-ip-mask-md5-name-or-service-not-known).

## Troubleshooting PostgreSQL with Patroni

In case you are experiencing any issues connecting through PgBouncer, the first place to check is always the logs for PostgreSQL (which is run through Patroni):

```shell
sudo gitlab-ctl tail patroni
```

### Consul and PostgreSQL with Patroni changes not taking effect

Due to the potential impacts, `gitlab-ctl reconfigure` only reloads Consul and PostgreSQL, it will not restart the services. However, not all changes can be activated by reloading.

To restart either service, run `gitlab-ctl restart consul` or `gitlab-ctl restart patroni` respectively.

For PostgreSQL with Patroni, to prevent the primary node from being failed over automatically, it's safest to stop all secondaries first, then restart the primary and finally restart the secondaries again.

On the Consul server nodes, it is important to restart the Consul service in a controlled fashion. Read our [Consul documentation](../consul.md#restart-consul) for instructions on how to restart the service.

### PgBouncer error `ERROR: pgbouncer cannot connect to server`

You may get this error when running `gitlab-rake gitlab:db:configure` or you
may see the error in the PgBouncer log file.

```plaintext
PG::ConnectionBad: ERROR:  pgbouncer cannot connect to server
```

The problem may be that your PgBouncer node's IP address is not included in the
`trust_auth_cidr_addresses` setting in `/etc/gitlab/gitlab.rb` on the database nodes.

You can confirm that this is the issue by checking the PostgreSQL log on the master
database node. If you see the following error then `trust_auth_cidr_addresses`
is the problem.

```plaintext
2018-03-29_13:59:12.11776 FATAL:  no pg_hba.conf entry for host "123.123.123.123", user "pgbouncer", database "gitlabhq_production", SSL off
```

To fix the problem, add the IP address to `/etc/gitlab/gitlab.rb`.

```ruby
postgresql['trust_auth_cidr_addresses'] = %w(123.123.123.123/32 <other_cidrs>)
```

[Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
