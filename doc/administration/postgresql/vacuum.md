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
settings when monitoring shows that autovacuum cannot keep up with dead tuples.
The goal is to let autovacuum reclaim dead tuples as fast as your workload creates them,
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

Per-table settings override the cluster-wide values for that table only. Use monitoring to find
which tables fall behind, and test changes in a non-production environment first.

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
