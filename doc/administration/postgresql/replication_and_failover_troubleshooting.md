---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting PostgreSQL replication and failover for Linux package installations
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

When working with PostgreSQL replication and failover, you might encounter the following issues.

## Consul and PostgreSQL changes not taking effect

Due to the potential impacts, `gitlab-ctl reconfigure` only reloads Consul and PostgreSQL, it does not restart the services. However, not all changes can be activated by reloading.

To restart either service, run `gitlab-ctl restart SERVICE`

For PostgreSQL, it is usually safe to restart the leader node by default. Automatic failover defaults to a 1 minute timeout. Provided the database returns before then, nothing else needs to be done.

On the Consul server nodes, it is important to [restart the Consul service](../consul.md#restart-consul) in a controlled manner.

## PgBouncer error `ERROR: pgbouncer cannot connect to server`

You may get this error when running `gitlab-rake gitlab:db:configure` or you
may see the error in the PgBouncer log file.

```plaintext
PG::ConnectionBad: ERROR:  pgbouncer cannot connect to server
```

The problem may be that your PgBouncer node's IP address is not included in the
`trust_auth_cidr_addresses` setting in `/etc/gitlab/gitlab.rb` on the database nodes.

You can confirm that this is the issue by checking the PostgreSQL log on the leader
database node. If you see the following error then `trust_auth_cidr_addresses`
is the problem.

```plaintext
2018-03-29_13:59:12.11776 FATAL:  no pg_hba.conf entry for host "123.123.123.123", user "pgbouncer", database "gitlabhq_production", SSL off
```

To fix the problem, add the IP address to `/etc/gitlab/gitlab.rb`.

```ruby
postgresql['trust_auth_cidr_addresses'] = %w(123.123.123.123/32 <other_cidrs>)
```

[Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## PgBouncer nodes don't fail over after Patroni switchover

Due to a [known issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8166) that
affects versions of GitLab prior to 16.5.0, the automatic failover of PgBouncer nodes does not
happen after a [Patroni switchover](../postgresql/replication_and_failover.md#manual-failover-procedure-for-patroni). In this
example, GitLab failed to detect a paused database, then attempted to `RESUME` a
not-paused database:

```plaintext
INFO -- : Running: gitlab-ctl pgb-notify --pg-database gitlabhq_production --newhost database7.example.com --user pgbouncer --hostuser gitlab-consul
ERROR -- : STDERR: Error running command: GitlabCtl::Errors::ExecutionError
ERROR -- : STDERR: ERROR: ERROR:  database gitlabhq_production is not paused
```

To ensure a [Patroni switchover](../postgresql/replication_and_failover.md#manual-failover-procedure-for-patroni) succeeds,
you must manually restart the PgBouncer service on all PgBouncer nodes with this command:

```shell
gitlab-ctl restart pgbouncer
```

## Reinitialize a replica

If a replica cannot start or rejoin the cluster, or when it lags behind and cannot catch up, it might be necessary to reinitialize the replica:

1. [Check the replication status](../postgresql/replication_and_failover.md#check-replication-status) to confirm which server
   needs to be reinitialized. For example:

   ```plaintext
   + Cluster: postgresql-ha (6970678148837286213) ------+---------+--------------+----+-----------+
   | Member                              | Host         | Role    | State        | TL | Lag in MB |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   | gitlab-database-1.example.com       | 172.18.0.111 | Replica | running      | 55 |         0 |
   | gitlab-database-2.example.com       | 172.18.0.112 | Replica | start failed |    |   unknown |
   | gitlab-database-3.example.com       | 172.18.0.113 | Leader  | running      | 55 |           |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   ```

1. Sign in to the broken server and reinitialize the database and replication. Patroni shuts
   down PostgreSQL on that server, remove the data directory, and reinitialize it from scratch:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica --member gitlab-database-2.example.com
   ```

   This can be run on any Patroni node, but be aware that `sudo gitlab-ctl patroni reinitialize-replica`
   without `--member` restarts the server it is run on.
   You should run it locally on the broken server to reduce the risk of
   unintended data loss.
1. Monitor the logs:

   ```shell
   sudo gitlab-ctl tail patroni
   ```

## Reset the Patroni state in Consul

WARNING:
Resetting the Patroni state in Consul is a potentially destructive process. Make sure that you have a healthy database backup first.

As a last resort you can reset the Patroni state in Consul completely.

This may be required if your Patroni cluster is in an unknown or bad state and no node can start:

```plaintext
+ Cluster: postgresql-ha (6970678148837286213) ------+---------+---------+----+-----------+
| Member                              | Host         | Role    | State   | TL | Lag in MB |
+-------------------------------------+--------------+---------+---------+----+-----------+
| gitlab-database-1.example.com       | 172.18.0.111 | Replica | stopped |    |   unknown |
| gitlab-database-2.example.com       | 172.18.0.112 | Replica | stopped |    |   unknown |
| gitlab-database-3.example.com       | 172.18.0.113 | Replica | stopped |    |   unknown |
+-------------------------------------+--------------+---------+---------+----+-----------+
```

**Before deleting the Patroni state in Consul**,
[try and resolve the `gitlab-ctl` errors](#errors-running-gitlab-ctl) on the Patroni nodes.

This process results in a reinitialized Patroni cluster when
the first Patroni node starts.

To reset the Patroni state in Consul:

1. Take note of the Patroni node that was the leader, or that the application thinks is the current leader,
   if the current state shows more than one, or none:
   - Look on the PgBouncer nodes in `/var/opt/gitlab/consul/databases.ini`,
     which contains the hostname of the current leader.
   - Look in the Patroni logs `/var/log/gitlab/patroni/current` (or the older rotated and
     compressed logs `/var/log/gitlab/patroni/@40000*`) on **all** database nodes to see
     which server was most recently identified as the leader by the cluster:

     ```plaintext
     INFO: no action. I am a secondary (database1.local) and following a leader (database2.local)
     ```

1. Stop Patroni on all nodes:

   ```shell
   sudo gitlab-ctl stop patroni
   ```

1. Reset the state in Consul:

   ```shell
   /opt/gitlab/embedded/bin/consul kv delete -recurse /service/postgresql-ha/
   ```

1. Start one Patroni node, which initializes the Patroni cluster to elect as a leader.
   It's highly recommended to start the previous leader (noted in the first step),
   so as to not lose existing writes that may have not been replicated because
   of the broken cluster state:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Start all other Patroni nodes that join the Patroni cluster as replicas:

   ```shell
   sudo gitlab-ctl start patroni
   ```

If you are still seeing issues, the next step is restoring the last healthy backup.

## Errors in the Patroni log about a `pg_hba.conf` entry for `127.0.0.1`

The following log entry in the Patroni log indicates the replication is not working
and a configuration change is needed:

```plaintext
FATAL:  no pg_hba.conf entry for replication connection from host "127.0.0.1", user "gitlab_replicator"
```

To fix the problem, ensure the loopback interface is included in the CIDR addresses list:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   postgresql['trust_auth_cidr_addresses'] = %w(<other_cidrs> 127.0.0.1/32)
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. Check that [all the replicas are synchronized](../postgresql/replication_and_failover.md#check-replication-status)

## Error: requested start point is ahead of the Write Ahead Log (WAL) flush position

This error in Patroni logs indicates that the database is not replicating:

```plaintext
FATAL:  could not receive data from WAL stream:
ERROR:  requested starting point 0/5000000 is ahead of the WAL flush position of this server 0/4000388
```

This example error is from a replica that was initially misconfigured, and had never replicated.

Fix it [by reinitializing the replica](#reinitialize-a-replica).

## Patroni fails to start with `MemoryError`

Patroni may fail to start, logging an error and stack trace:

```plaintext
MemoryError
Traceback (most recent call last):
  File "/opt/gitlab/embedded/bin/patroni", line 8, in <module>
    sys.exit(main())
[..]
  File "/opt/gitlab/embedded/lib/python3.7/ctypes/__init__.py", line 273, in _reset_cache
    CFUNCTYPE(c_int)(lambda: None)
```

If the stack trace ends with `CFUNCTYPE(c_int)(lambda: None)`, this code triggers `MemoryError`
if the Linux server has been hardened for security.

The code causes Python to write temporary executable files, and if it cannot find a file system in which to do this. For example, if `noexec` is set on the `/tmp` file system, it fails with `MemoryError` ([read more in the issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6184)).

## Errors running `gitlab-ctl`

Patroni nodes can get into a state where `gitlab-ctl` commands fail
and `gitlab-ctl reconfigure` cannot fix the node.

If this co-incides with a version upgrade of PostgreSQL, [follow a different procedure](#postgresql-major-version-upgrade-fails-on-a-patroni-replica)

One common symptom is that `gitlab-ctl` cannot determine
information it needs about the installation if the database server is failing to start:

```plaintext
Malformed configuration JSON file found at /opt/gitlab/embedded/nodes/<HOSTNAME>.json.
This usually happens when your last run of `gitlab-ctl reconfigure` didn't complete successfully.
```

```plaintext
Error while reinitializing replica on the current node: Attributes not found in
/opt/gitlab/embedded/nodes/<HOSTNAME>.json, has reconfigure been run yet?
```

Similarly, the nodes file (`/opt/gitlab/embedded/nodes/<HOSTNAME>.json`) should contain a lot of information,
but might get created with only:

```json
{
  "name": "<HOSTNAME>"
}
```

The following process for fixing this includes reinitializing this replica:
the current state of PostgreSQL on this node is discarded:

1. Shut down the Patroni and (if present) PostgreSQL services:

   ```shell
   sudo gitlab-ctl status
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl stop postgresql
   ```

1. Remove `/var/opt/gitlab/postgresql/data` in case its state prevents
   PostgreSQL from starting:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   ```

   **Take care with this step to avoid data loss**.
   This step can be also achieved by renaming `data/`:
   make sure there's enough free disk for a new copy of the primary database,
   and remove the extra directory when the replica is fixed.

1. With PostgreSQL not running, the nodes file now gets created successfully:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Start Patroni:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Monitor the logs and check the cluster state:

   ```shell
   sudo gitlab-ctl tail patroni
   sudo gitlab-ctl patroni members
   ```

1. Re-run `reconfigure` again:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Reinitialize the replica if `gitlab-ctl patroni members` indicates this is needed:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica
   ```

If this procedure doesn't work **and** if the cluster is unable to elect a leader,
[there is a another fix](#reset-the-patroni-state-in-consul) which should only be
used as a last resort.

## PostgreSQL major version upgrade fails on a Patroni replica

A Patroni **replica** can get stuck in a loop during `gitlab-ctl pg-upgrade`, and
the upgrade fails.

An example set of symptoms is as follows:

1. A `postgresql` service is defined,
   which shouldn't usually be present on a Patroni node. It is present because
   `gitlab-ctl pg-upgrade` adds it to create a new empty database:

   ```plaintext
   run: patroni: (pid 1972) 1919s; run: log: (pid 1971) 1919s
   down: postgresql: 1s, normally up, want up; run: log: (pid 1973) 1919s
   ```

1. PostgreSQL generates `PANIC` log entries in
   `/var/log/gitlab/postgresql/current` as Patroni is removing
   `/var/opt/gitlab/postgresql/data` as part of reinitializing the replica:

   ```plaintext
   DETAIL:  Could not open file "pg_xact/0000": No such file or directory.
   WARNING:  terminating connection because of crash of another server process
   LOG:  all server processes terminated; reinitializing
   PANIC:  could not open file "global/pg_control": No such file or directory
   ```

1. In `/var/log/gitlab/patroni/current`, Patroni logs the following.
   The local PostgreSQL version is different from the cluster leader:

   ```plaintext
   INFO: trying to bootstrap from leader 'HOSTNAME'
   pg_basebackup: incompatible server version 12.6
   pg_basebackup: removing data directory "/var/opt/gitlab/postgresql/data"
   ERROR: Error when fetching backup: pg_basebackup exited with code=1
   ```

**Important**: This workaround applies when the Patroni cluster is in the following state:

- The [leader has been successfully upgraded to the new major version](../postgresql/replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster).
- The step to upgrade PostgreSQL on replicas is failing.

This workaround completes the PostgreSQL upgrade on a Patroni replica
by setting the node to use the new PostgreSQL version, and then reinitializing
it as a replica in the new cluster that was created
when the leader was upgraded:

1. Check the cluster status on all nodes to confirm which is the leader
   and what state the replicas are in

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. Replica: check which version of PostgreSQL is active:

   ```shell
   sudo ls -al /opt/gitlab/embedded/bin | grep postgres
   ```

1. Replica: ensure the nodes file is correct and `gitlab-ctl` can run. This resolves
   the [errors running `gitlab-ctl`](#errors-running-gitlab-ctl) issue if the replica
   has any of those errors as well:

   ```shell
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl reconfigure
   ```

1. Replica: relink the PostgreSQL binaries to the required version
   to fix the `incompatible server version` error:

   1. Edit `/etc/gitlab/gitlab.rb` and specify the required version:

      ```ruby
      postgresql['version'] = 13
      ```

   1. Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Check the binaries are relinked. The binaries distributed for
      PostgreSQL vary between major releases, it's typical to
      have a small number of incorrect symbolic links:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. Replica: ensure PostgreSQL is fully reinitialized for the specified version:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   sudo gitlab-ctl reconfigure
   ```

1. Replica: optionally monitor the database in two additional terminal sessions:

   - Disk use increases as `pg_basebackup` runs. Track progress of the
     replica initialization with:

     ```shell
     cd /var/opt/gitlab/postgresql
     watch du -sh data
     ```

   - Monitor the process in the logs:

     ```shell
     sudo gitlab-ctl tail patroni
     ```

1. Replica: Start Patroni to reinitialize the replica:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Replica: After it completes, remove the hardcoded version from `/etc/gitlab/gitlab.rb`:

   1. Edit `/etc/gitlab/gitlab.rb` and remove `postgresql['version']`.
   1. Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Check the correct binaries are linked:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. Check the cluster status on all nodes:

   ```shell
   sudo gitlab-ctl patroni members
   ```

Repeat this procedure on the other replica if required.

## Issues with other components

If you're running into an issue with a component not outlined here, be sure to check the troubleshooting section of their specific documentation page:

- [Consul](../consul.md#troubleshooting-consul)
- [PostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#troubleshooting)
