---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Geo PostgreSQL replication
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

The following sections outline troubleshooting steps for fixing replication error messages (indicated by `Database replication working? ... no` in the
[`geo:check` output](common.md#health-check-rake-task).
The instructions present here mostly assume a single-node Geo Linux package deployment, and might need to be adapted to different environments.

## Removing an inactive replication slot

Replication slots are marked as 'inactive' when the replication client (a secondary site) connected to the slot disconnects.
Inactive replication slots cause WAL files to be retained, because they are sent to the client when it reconnects and the slot becomes active once more.
If the secondary site is not able to reconnect, use the following steps to remove its corresponding inactive replication slot:

1. [Start a PostgreSQL console session](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-postgresql-database) on the Geo primary site's database node:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

   NOTE:
   Using `gitlab-rails dbconsole` does not work, because managing replication slots requires superuser permissions.

1. View the replication slots and remove them if they are inactive:

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

   Slots where `active` is `f` are inactive.

- If this slot should be active, because you have a **secondary** site configured using that slot:
  - Look for the [PostgreSQL logs](../../../logs/_index.md#postgresql-logs) for the **secondary** site,
     to view why the replication is not running.
  - If the secondary site is no longer able to reconnect:

    1. Remove the slot using the PostgreSQL console session:

       ```sql
       SELECT pg_drop_replication_slot('<name_of_inactive_slot>');
       ```

    1. [Re-initiate the replication process](../../setup/database.md#step-3-initiate-the-replication-process),
       which recreates the replication slot correctly.

- If you are no longer using the slot (for example, you no longer have Geo enabled), follow the steps [to remove that Geo site](../remove_geo_site.md).

## Message: `WARNING: oldest xmin is far in the past` and `pg_wal` size growing

If a replication slot is inactive,
the `pg_wal` logs corresponding to the slot are reserved forever
(or until the slot is active again). This causes continuous disk usage growth
and the following messages appear repeatedly in the
[PostgreSQL logs](../../../logs/_index.md#postgresql-logs):

```plaintext
WARNING: oldest xmin is far in the past
HINT: Close open transactions soon to avoid wraparound problems.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```

To fix this, you should [remove the inactive replication slot](#removing-an-inactive-replication-slot) and re-initiate the replication.

## Message: `ERROR:  replication slots can only be used if max_replication_slots > 0`?

This means that the `max_replication_slots` PostgreSQL variable needs to
be set on the **primary** database. This setting defaults to 1. You may need to
increase this value if you have more **secondary** sites.

Be sure to restart PostgreSQL for this to take effect. See the
[PostgreSQL replication setup](../../setup/database.md#postgresql-replication) guide for more details.

## Message: `replication slot "geo_secondary_my_domain_com" does not exist`

This error occurs when PostgreSQL does not have a replication slot for the
**secondary** site by that name:

```plaintext
FATAL:  could not start WAL streaming: ERROR:  replication slot "geo_secondary_my_domain_com" does not exist
```

You may want to rerun the [replication process](../../setup/database.md) on the **secondary** site .

## Message: "Command exceeded allowed execution time" when setting up replication?

This may happen while [initiating the replication process](../../setup/database.md#step-3-initiate-the-replication-process) on the **secondary** site,
and indicates your initial dataset is too large to be replicated in the default timeout (30 minutes).

Re-run `gitlab-ctl replicate-geo-database`, but include a larger value for
`--backup-timeout`:

```shell
sudo gitlab-ctl \
   replicate-geo-database \
   --host=<primary_node_hostname> \
   --slot-name=<secondary_slot_name> \
   --backup-timeout=21600
```

This gives the initial replication up to six hours to complete, rather than
the default 30 minutes. Adjust as required for your installation.

## Message: "PANIC: could not write to file `pg_xlog/xlogtemp.123`: No space left on device"

Determine if you have any unused replication slots in the **primary** database. This can cause large amounts of
log data to build up in `pg_xlog`.

[Removing the inactive slots](#removing-an-inactive-replication-slot) can reduce the amount of space used in the `pg_xlog`.

## Message: "ERROR: canceling statement due to conflict with recovery"

This error message occurs infrequently under typical usage, and the system is resilient
enough to recover.

However, under certain conditions, some database queries on secondaries may run
excessively long, which increases the frequency of this error message. This can lead to a situation
where some queries never complete due to being canceled on every replication.

These long-running queries are
[planned to be removed in the future](https://gitlab.com/gitlab-org/gitlab/-/issues/34269),
but as a workaround, we recommend enabling
[`hot_standby_feedback`](https://www.postgresql.org/docs/10/hot-standby.html#HOT-STANDBY-CONFLICT).
This increases the likelihood of bloat on the **primary** site as it prevents
`VACUUM` from removing recently-dead rows. However, it has been used
successfully in production on GitLab.com.

To enable `hot_standby_feedback`, add the following to `/etc/gitlab/gitlab.rb`
on the **secondary** site:

```ruby
postgresql['hot_standby_feedback'] = 'on'
```

Then reconfigure GitLab:

```shell
sudo gitlab-ctl reconfigure
```

To help us resolve this problem, consider commenting on
[the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/4489).

## Message: `server certificate for "PostgreSQL" does not match host name`

If you see this error:

```plaintext
FATAL:  could not connect to the primary server: server certificate for "PostgreSQL" does not match host name
```

This happens because the PostgreSQL certificate that the Linux package automatically creates contains
the Common Name `PostgreSQL`, but the replication is connecting to a different host and GitLab attempts to use
the `verify-full` SSL mode by default.

To fix this issue, you can either:

- Use the `--sslmode=verify-ca` argument with the `replicate-geo-database` command.
- For an already replicated database, change `sslmode=verify-full` to `sslmode=verify-ca`
  in `/var/opt/gitlab/postgresql/data/gitlab-geo.conf` and run `gitlab-ctl restart postgresql`.
- [Configure SSL for PostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#configuring-ssl)
  with a custom certificate (including the host name that's used to connect to the database in the CN or SAN)
  instead of using the automatically generated certificate.

## Message: `LOG:  invalid CIDR mask in address`

This happens on wrongly-formatted addresses in `postgresql['md5_auth_cidr_addresses']`.

```plaintext
2020-03-20_23:59:57.60499 LOG:  invalid CIDR mask in address "***"
2020-03-20_23:59:57.60501 CONTEXT:  line 74 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

To fix this, update the IP addresses in `/etc/gitlab/gitlab.rb` under `postgresql['md5_auth_cidr_addresses']`
to respect the CIDR format (for example, `10.0.0.1/32`).

## Message: `LOG:  invalid IP mask "md5": Name or service not known`

This happens when you have added IP addresses without a subnet mask in `postgresql['md5_auth_cidr_addresses']`.

```plaintext
2020-03-21_00:23:01.97353 LOG:  invalid IP mask "md5": Name or service not known
2020-03-21_00:23:01.97354 CONTEXT:  line 75 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

To fix this, add the subnet mask in `/etc/gitlab/gitlab.rb` under `postgresql['md5_auth_cidr_addresses']`
to respect the CIDR format (for example, `10.0.0.1/32`).

## Message: `Found data in the gitlabhq_production database`

If you receive the error `Found data in the gitlabhq_production database!` when running
`gitlab-ctl replicate-geo-database`, data was detected in the `projects` table. When one or more projects are detected, the operation
is aborted to prevent accidental data loss. To bypass this message, pass the `--force` option to the command.

## Message: `FATAL:  could not map anonymous shared memory: Cannot allocate memory`

If you see this message, it means that the secondary site's PostgreSQL tries to request memory that is higher than the available memory. There is an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/381585) that tracks this problem.

Example error message in Patroni logs (located at `/var/log/gitlab/patroni/current` for Linux package installations):

```plaintext
2023-11-21_23:55:18.63727 FATAL:  could not map anonymous shared memory: Cannot allocate memory
2023-11-21_23:55:18.63729 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory, swap space, or huge pages. To reduce the request size (currently 17035526144 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
```

The workaround is to increase the memory available to the secondary site's PostgreSQL nodes to match the memory requirements of the primary site's PostgreSQL nodes.

## Investigate causes of database replication lag

If the output of `sudo gitlab-rake geo:status` shows that `Database replication lag` remains significantly high over time, the primary node in database replication can be checked to determine the status of lag for
different parts of the database replication process. These values are known as `write_lag`, `flush_lag`, and `replay_lag`. For more information, see
[the official PostgreSQL documentation](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-REPLICATION-VIEW).

Run the following command from the primary Geo node's database to provide relevant output:

```shell
gitlab-psql -xc 'SELECT write_lag,flush_lag,replay_lag FROM pg_stat_replication;'

-[ RECORD 1 ]---------------
write_lag  | 00:00:00.072392
flush_lag  | 00:00:00.108168
replay_lag | 00:00:00.108283
```

If one or more of these values is significantly high, this could indicate a problem and should be investigated further. When determining the cause, consider that:

- `write_lag` indicates the time since when WAL bytes have been sent by the primary, then received to the secondary, but not yet flushed or applied.
- A high `write_lag` value may indicate degraded network performance or insufficient network speed between the primary and secondary nodes.
- A high `flush_lag` value may indicate degraded or sub-optimal disk I/O performance with the secondary node's storage device.
- A high `replay_lag` value may indicate long running transactions in PostgreSQL, or the saturation of a needed resource like the CPU.
- The difference in time between `write_lag` and `flush_lag` indicates that WAL bytes have been sent to the underlying storage system, but it has not reported that they were flushed.
  This data is most likely not fully written to a persistent storage, and likely held in some kind of volatile write cache.
- The difference between `flush_lag` and `replay_lag` indicates WAL bytes that have been successfully persisted to storage, but could not be replayed by the database system.
