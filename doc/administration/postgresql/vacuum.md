---
stage: Data Access
group: Database Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tune PostgreSQL autovacuum
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Use this page to tune PostgreSQL autovacuum and to troubleshoot common autovacuum problems.

## How autovacuum works

PostgreSQL uses [multiversion concurrency control (MVCC)](https://www.postgresql.org/docs/current/mvcc-intro.html).
When you update or delete a row, PostgreSQL does not remove the old row version right away.
Instead, PostgreSQL marks the old version as dead and keeps it until no running transaction can
still see it. Autovacuum is the background process that removes these dead row versions, also
called dead tuples. It reclaims the space they occupy, updates the planner statistics, and
maintains the visibility map.

Autovacuum is critical for database health. Without it, dead rows accumulate as table and index
bloat. Bloat slows down queries, wastes disk space, and inflates backup and maintenance times.
Autovacuum also prevents
[transaction ID wraparound](https://www.postgresql.org/docs/current/routine-vacuuming.html#VACUUM-FOR-WRAPAROUND),
which stops the database from accepting writes.

### When autovacuum runs

Autovacuum periodically checks each table and runs a vacuum when the number of dead tuples passes
this threshold:

```plaintext
autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor × number_of_live_tuples
```

By default, PostgreSQL sets `autovacuum_vacuum_scale_factor` to `0.2`. PostgreSQL then vacuums a
table only after 20% of its rows become dead. On large tables, 20% is a large number of dead
tuples. A table then bloats for a long time before autovacuum acts. To reduce this delay, GitLab
Linux package installations lower `autovacuum_vacuum_scale_factor` to `0.02` (2%) by default. The
largest or most frequently updated tables can still need a lower per-table value. See
[Tune large tables individually](#tune-large-tables-individually).

## Recommended autovacuum settings

GitLab Linux package installations ship autovacuum defaults that suit most workloads. Change these
settings when [monitoring](#monitor-autovacuum) shows that autovacuum cannot keep up with dead
tuples. The goal is to let autovacuum reclaim dead tuples as fast as your workload creates them,
without starving the database of I/O.

The changes with the largest impact are usually raising `autovacuum_vacuum_cost_limit`, raising
`autovacuum_max_workers`, and lowering the scale factor on the largest tables. Treat the values in
this section as starting points and validate them against your own workload.

### Cluster-wide settings

For GitLab Linux package installations, set cluster-wide values in `/etc/gitlab/gitlab.rb`, then run
`sudo gitlab-ctl reconfigure`.

```ruby
postgresql['autovacuum_max_workers'] = "<value>"
postgresql['autovacuum_vacuum_cost_limit'] = "<value>"
postgresql['autovacuum_vacuum_cost_delay'] = "<value>"
postgresql['maintenance_work_mem'] = "<value>"
```

For an [external PostgreSQL instance](external.md), set the same parameters in `postgresql.conf`
instead, then reload PostgreSQL:

```ini
autovacuum_max_workers = <value>
autovacuum_vacuum_cost_limit = <value>
autovacuum_vacuum_cost_delay = <value>
maintenance_work_mem = <value>
autovacuum_work_mem = <value>
```

Reload PostgreSQL with `SELECT pg_reload_conf();` or by reloading the service. For both
installation types, settings such as `autovacuum_max_workers` require a full PostgreSQL restart.
A reload or reconfigure is not enough.

The following settings have the largest effect on whether autovacuum keeps up:

| Setting                          | Recommended value           | Description                                                                                                                                                                                                                                                                                                                                                 |
|----------------------------------|-----------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `autovacuum_max_workers`         | About 25% of the vCPU count | Maximum number of autovacuum processes that run at the same time. The default is often too low for large, multi-core database hosts. Each worker adds memory and I/O load.                                                                                                                                                                                  |
| `autovacuum_vacuum_scale_factor` | `0.01` to `0.02`            | Fraction of a table's rows that must be dead before autovacuum runs. GitLab lowers the PostgreSQL default to `0.02`. Lower it further for large, frequently updated tables. See [Tune large tables individually](#tune-large-tables-individually).                                                                                                          |
| `autovacuum_vacuum_cost_limit`   | 800 for SSD                 | I/O cost autovacuum accumulates before it pauses. When set to `-1`, it inherits the value of `vacuum_cost_limit`. That value is well below the throughput of modern SSD-backed storage. Set it explicitly. Raising it is often the highest-impact change.                                                                                                         |
| `autovacuum_vacuum_cost_delay`   | 2 ms                        | Time autovacuum pauses after it reaches the cost limit. Lower it to make autovacuum more aggressive. Never set it to `0`. See [Settings to avoid](#settings-to-avoid).                                                                                                                                                                                      |
| `maintenance_work_mem`           | 1 GB to 2 GB                | Memory for maintenance operations such as index creation. Each autovacuum worker also uses this much to track dead tuples when `autovacuum_work_mem` is `-1`. A low value makes a worker scan indexes repeatedly on large tables. Size it against the available RAM and the worker count.                                                                   |
| `autovacuum_work_mem`            | 512 MB                      | Memory each autovacuum worker uses to track dead tuples. When set to `-1`, workers inherit `maintenance_work_mem`. Total autovacuum memory then scales with the worker count. PostgreSQL 17 removed the 1 GB cap on this memory. Bound it explicitly when you raise the worker count. Linux package installations cannot set this parameter in `gitlab.rb`. |
| `autovacuum_naptime`             | A few seconds (optional)    | Time autovacuum waits between checks of a database. Lower it for databases with rapid churn so autovacuum responds faster.                                                                                                                                                                                                                                  |

### Tune large tables individually

The largest tables can bloat even with a low cluster-wide scale factor. For these tables, set a
lower per-table scale factor or threshold directly in PostgreSQL. A scale factor around `0.01` (1%)
is common for very large, frequently updated tables:

```sql
ALTER TABLE <table_name> SET (autovacuum_vacuum_scale_factor = 0.01);
```

Per-table settings override the cluster-wide values for that table only. Use
[monitoring](#monitor-autovacuum) to find which tables fall behind, and test changes in a
non-production environment first.

### Settings to avoid

> [!warning]
> Do not disable autovacuum (`autovacuum = off`). Without autovacuum, dead tuples accumulate. The
> database then moves toward transaction ID wraparound. Wraparound stops the database from
> accepting writes.

Avoid these configurations:

- `autovacuum_vacuum_cost_delay = 0` removes I/O throttling. Autovacuum then runs without pausing
  and can saturate disk I/O. Queries slow down.
- The default scale factor on the largest tables. These tables then vacuum too rarely. Set a lower
  per-table value instead.
- Relying on `-1` inheritance for `autovacuum_vacuum_cost_limit`. The effective value then lives in
  another setting, where you can overlook it. Set it explicitly.

## Monitor autovacuum

### Database diagnostics page

{{< history >}}

- Vacuum activity [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239928) in GitLab 19.2.
- Autovacuum settings and findings [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242428) in GitLab 19.4.
- Per-table overrides and scale factor risk [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245561) in GitLab 19.5.

{{< /history >}}

The Database diagnostics page shows vacuum activity and autovacuum settings for each database.

Prerequisites:

- You must have administrator access.

To view the page:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Monitoring** > **Database diagnostics**.

Two sections of the page relate to autovacuum. Each section has one card for each database in the
installation.

The **Vacuum information** section contains the **Vacuum activity** panel. This panel has one row
for each vacuum running right now. The columns are Table, Type, Running for, Phase, Heap scanned,
Indexes processed, Dead tuples, Index passes, and Delay time. A row can carry these badges:

- **Anti-wraparound**: the vacuum is preventing transaction ID wraparound. This vacuum does not
  auto-cancel. Do not terminate it. If you do, the database can shut down to protect data.
- **Long-running**: the vacuum has run for more than 6 hours. Large tables can take this long,
  but a vacuum that never completes can be blocked or starved of resources.
- **Memory pressure**: the vacuum needed more than one index pass. The dead-tuple store filled up
  before the heap scan completed. Raise `maintenance_work_mem` or `autovacuum_work_mem`.

The **Autovacuum configuration** section contains these panels:

- **Effective settings**: the autovacuum settings the database actually uses, read from
  `pg_settings`. A **Status** column marks each misconfiguration the checks find. When
  `autovacuum_vacuum_cost_limit` is `-1`, the panel also shows the effective limit it inherits
  from `vacuum_cost_limit`.
- **Per-table overrides**: tables that set an autovacuum parameter in their storage parameters.
  The panel shows the size, estimated row count, and overrides of each table. A table that
  disables autovacuum carries an **Autovacuum disabled** badge. The panel lists up to 50 tables,
  with the tables that disable autovacuum first. The panel is hidden when no table has overrides.
- **Scale factor risk**: large tables where the scale factor in effect is still high. The panel
  is hidden when the check finds no such table.

Some findings concern a table, not a single setting. These findings appear as alerts above the
panels. For the conditions behind each finding, see [Autovacuum findings](#autovacuum-findings).

> [!note]
> The **Vacuum activity** panel needs PostgreSQL 17 or later. On earlier versions, the panel is
> empty. The Delay time column needs PostgreSQL 18 or later. The Type and Running for columns, and
> the **Anti-wraparound** badge, need a database role that can read the activity of other
> backends. Grant the role membership in `pg_monitor`. Without this membership, the progress
> columns still work, but the Type, Running for, and Anti-wraparound fields show `Not available`.

Both sections read from the primary database, because autovacuum runs only there.

### Report diagnostics on the console

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251254) in GitLab 19.4.
- Tasks for a single check [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251735) in GitLab 19.4.
- Menu removed for a single check [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257133) in GitLab 19.5.

{{< /history >}}

Use the Rake task when you have no access to the UI, or when you want the report from a script.

For Linux package installations:

```shell
sudo gitlab-rake gitlab:db:diagnostics
```

By default, the task reports on every database. To select databases, pass their names:

```shell
sudo gitlab-rake "gitlab:db:diagnostics[main,ci]"
```

To run the autovacuum check only, use its own task. It accepts the same database names:

```shell
sudo gitlab-rake "gitlab:db:diagnostics:autovacuum_settings[main,ci]"
```

The report prints a summary first, then a section for each check. The **Autovacuum settings**
section lists the findings, the effective settings, the per-table overrides, and the scale factor
risks for each database.

The task exits with status `1` when it finds an error, so a monitoring job can use the exit code.

In a terminal, the task shows a menu to open each section when it runs more than one check. When
it runs one check, or when you pipe or redirect the output, the task prints the whole report.

> [!note]
> The Rake task reports settings only. It does not show vacuum activity. Vacuum activity is
> available only on the [Database diagnostics page](#database-diagnostics-page).

### Autovacuum findings

The Database diagnostics page and the Rake task use the same checks. Both report the same
findings. The first five findings each concern one setting and appear in the **Status** column of
the **Effective settings** panel. The last two concern tables and appear as alerts.

| Finding             | Setting                          | Severity | Reported when                                                                                                                                                                                                                                                                                                                                             | Action                                                                                                                                                                                                                  |
|---------------------|----------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Disabled            | `autovacuum`                     | Error    | `autovacuum` is `off`. Dead tuples are never reclaimed automatically. This risks bloat and eventually transaction ID wraparound.                                                                                                                                                                                                                          | Turn autovacuum on. See [Settings to avoid](#settings-to-avoid).                                                                                                                                                        |
| Throttling disabled | `autovacuum_vacuum_cost_delay`   | Error    | The cost delay is `0`. Autovacuum then runs at full speed. This can cause write storms and replication lag.                                                                                                                                                                                                                                               | Set a non-zero delay. See [Settings to avoid](#settings-to-avoid).                                                                                                                                                      |
| Low                 | `autovacuum_max_workers`         | Warning  | Fewer than three workers are configured. This can be too few for a large or decomposed database.                                                                                                                                                                                                                                                          | Raise the worker count. See [Cluster-wide settings](#cluster-wide-settings).                                                                                                                                            |
| Low                 | `autovacuum_vacuum_cost_limit`   | Warning  | The effective limit is `200` or less. That limit is likely too low for modern storage. The check uses the value inherited from `vacuum_cost_limit` when the setting is `-1`. Linux package installations ship `-1` by default. The PostgreSQL default for `vacuum_cost_limit` is `200`. This finding therefore appears on a default Linux package installation. | Set the limit explicitly. See [Cluster-wide settings](#cluster-wide-settings).                                                                                                                                          |
| Inherited           | `autovacuum_work_mem`            | Warning  | The setting is `-1`. Each worker inherits `maintenance_work_mem`.                                                                                                                                                                                                                                                                                         | Set it explicitly to bound the memory each worker uses. Linux package installations cannot set this parameter in `gitlab.rb`; tune `maintenance_work_mem` instead. See [Cluster-wide settings](#cluster-wide-settings). |
| Tables disabled     | Per-table `autovacuum_enabled`   | Error    | One or more tables set `autovacuum_enabled = false` in their storage parameters. Their dead tuples are never reclaimed automatically. The **Per-table overrides** panel marks each such table.                                                                                                                                                            | Turn autovacuum back on for each table with `ALTER TABLE <table_name> RESET (autovacuum_enabled);`.                                                                                                                     |
| Scale factor risk   | `autovacuum_vacuum_scale_factor` | Warning  | The cluster-wide scale factor is `0.1` or more, and one of the 20 largest tables is 10 GiB or more with a scale factor in effect of `0.1` or more. Linux package installations ship `0.02`. This finding therefore appears mainly on external PostgreSQL instances that keep the PostgreSQL default of `0.2`.                                             | Lower the cluster-wide scale factor, or set a per-table value on the listed tables. See [Tune large tables individually](#tune-large-tables-individually).                                                              |

The scale factor in effect is the per-table override when set, otherwise the cluster-wide value.
A per-table `autovacuum_vacuum_threshold` does not exempt a table. The check skips tables with
autovacuum disabled.

> [!note]
> The checks report only clear misconfigurations. The checks also use lower thresholds than the
> values in [Recommended autovacuum settings](#recommended-autovacuum-settings). A setting can
> pass the checks and still be too low for your workload. For example, three autovacuum workers
> passes the check, but is low for a host with many vCPUs.

### Check dead tuples and freeze age

Neither the Database diagnostics page nor the Rake task reports per-table dead tuples or freeze
age. Query the database for that information instead. On Linux package installations, connect
with:

```shell
sudo gitlab-psql
```

To find the tables with the most dead tuples, and when autovacuum last processed them:

```sql
SELECT schemaname, relname, n_live_tup, n_dead_tup, last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 20;
```

A rising `n_dead_tup` count, with `last_autovacuum` old or empty, means autovacuum cannot keep up
with that table. See
[Autovacuum cannot keep up with a table](#autovacuum-cannot-keep-up-with-a-table).

To find the freeze age of each table:

```sql
SELECT n.nspname AS schema_name, c.relname AS table_name, age(c.relfrozenxid) AS xid_age
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'm')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY xid_age DESC
LIMIT 20;
```

`xid_age` counts the transactions that ran after PostgreSQL last froze the table. Compare it
against `autovacuum_freeze_max_age`. The **Effective settings** panel reports this value. When a
table passes this value, PostgreSQL starts an anti-wraparound autovacuum on it. A freeze age that
keeps rising means autovacuum cannot freeze rows fast enough. See
[Transaction ID wraparound is approaching](#transaction-id-wraparound-is-approaching).

## Troubleshoot common issues

### Autovacuum cannot keep up with a table

A table accumulates dead tuples faster than autovacuum removes them. The dead-tuple count keeps
rising, the table bloats, and queries against it slow down. This problem has two common causes:

- A high rate of changes. A database migration, or an endpoint that updates rows often, creates
  dead tuples faster than autovacuum clears them.
- A busy table that uses the cluster-wide settings. Large, frequently updated tables often need
  their own autovacuum settings.

To find which tables fall behind, check the dead-tuple count and the time autovacuum last ran for
each table. See [Monitor autovacuum](#monitor-autovacuum). To resolve the problem:

- Set a lower per-table scale factor or threshold. For more information, see
  [Tune large tables individually](#tune-large-tables-individually).
- Raise `autovacuum_vacuum_cost_limit` and `autovacuum_max_workers`. For more information, see
  [Recommended autovacuum settings](#recommended-autovacuum-settings).
- If a migration or application change is the source of the churn, pause or revert it.

### Transaction ID wraparound is approaching

PostgreSQL assigns each transaction an ID (XID). As the oldest unfrozen XID ages, PostgreSQL runs
anti-wraparound autovacuums to freeze old rows. If these vacuums cannot complete, the database
eventually stops accepting writes to protect your data.

To track this risk, monitor the freeze age of each database and table. See
[Monitor autovacuum](#monitor-autovacuum). A rising freeze age means autovacuum is not freezing
rows fast enough.

To resolve it, make sure autovacuum runs and is not blocked. See
[Autovacuum cannot keep up with a table](#autovacuum-cannot-keep-up-with-a-table). If the database
has already stopped accepting writes, follow the recovery steps in
[Database is not accepting commands to avoid wraparound data loss](../troubleshooting/postgresql.md#database-is-not-accepting-commands-to-avoid-wraparound-data-loss).

### Autovacuum uses too many resources

Autovacuum creates I/O traffic that can slow down other queries. PostgreSQL throttles this traffic
with a cost-based delay. The delay is balanced across all running autovacuum workers. The total
I/O impact then stays about the same no matter how many workers run.

To reduce the effect on other queries, raise `autovacuum_vacuum_cost_delay` so workers pause more
often. A higher delay slows down vacuuming. Balance it against the need to keep up with dead
tuples. Never set the delay to `0`. This removes throttling entirely. For more information, see
[Settings to avoid](#settings-to-avoid).
