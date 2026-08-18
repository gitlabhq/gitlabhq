---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tune PostgreSQL
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You should tune PostgreSQL when:

- Other GitLab components are reconfigured or scaled up in a way that affects the database.
- The performance of your GitLab environment is impaired.
- GitLab uses an [external PostgreSQL service](external.md).

## Required settings for external instances

The following settings are required for externally managed PostgreSQL instances.

| Tunable setting        | Required value | More information |
|:-----------------------|:---------------|:-----------------|
| `work_mem`             | minimum `8 MB`  | This value is the Linux package default. In large deployments, if queries create temporary files, you should increase this setting. |
| `maintenance_work_mem` | minimum `64 MB` | You require [more for larger database servers](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8377#note_1728173087). |
| `max_connections`      | minimum `400`   | Set based on what the database host can serve. See [Determine your database host capacity](#determine-your-database-host-capacity-max_connections). The connection-demand formula gives frontend demand, not this value. |
| `shared_buffers`       | minimum `2 GB`  | You require more for larger database servers. The Linux package default is set to 25% of server RAM. |
| `statement_timeout`    | 15000 to 60000 | A statement timeout prevents runaway issues with locks and the database rejecting new clients. You should use values between 15 and 60 seconds (15000 to 60000 milliseconds), where one minute matches the Puma rack timeout setting. |
| `hot_standby_feedback` | `on` | For configurations with multiple nodes and [database load balancing](database_load_balancing.md#configure-database-load-balancing) configured, ensure that all replica nodes have `hot_standby_feedback` enabled to prevent lag buildup. |

You can configure some PostgreSQL settings for the specific database, rather than for all databases on the server.

- You might limit configuration to specific databases when hosting multiple databases on the same server.
- For guidance on where to apply configuration, consult your database administrator or vendor.
- For GCP Cloud SQL, you can set `statement_timeout` on a specific database or user, but not [as a database flag](https://cloud.google.com/sql/docs/postgres/flags#list-flags-postgres).
  For example: `ALTER DATABASE gitlab SET statement_timeout = '60s';`

## Plan your database connections

This formula computes the application's frontend connection demand - the number of connections
Rails opens to the database (or to PgBouncer). This is not the value to use for PostgreSQL
`max_connections`. See [Determine your database host capacity](#determine-your-database-host-capacity-max_connections)
for how to size `max_connections`.

> [!note]
> GitLab versions 16.0 and later use
> [two sets of database connections](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)
> for the `main` and `ci` tables. This doubles connection usage, even when the same PostgreSQL database
> serves both sets of tables.

GitLab uses database connections from multiple components. Proper connection planning prevents
database connection exhaustion and performance issues.

Each GitLab component uses database connections based on its configuration.
Sidekiq and Puma establish a pool of connections to PostgreSQL at initialization.
The number of connections in the pool can increase later if there are connection spikes or
temporary increases in demand:

- Configure database pool headroom with the environment variable `DB_POOL_HEADROOM`.
- When you tune PostgreSQL, plan for pool headroom but do not change it.
  GitLab deployments respond better to higher demand if more capacity is available:
  deploy more Sidekiq or Puma workers.

### Puma

```plaintext
Puma connections = puma['worker_processes'] × (puma['max_threads'] + DB_POOL_HEADROOM)
```

By default:

- `puma['worker_processes']` is based on CPU core count.
- `puma['max_threads']` is `4`.
- `DB_POOL_HEADROOM` is `10`.

Per-worker calculation: Each Puma worker uses 4 threads + 10 headroom, for a total of 14 connections.

Default calculation, assuming 8 vCPU: 8 workers × 14 connections per worker, for a total of 112 Puma connections.

### Sidekiq

```plaintext
Sidekiq connections = Number of Sidekiq processes × (sidekiq['concurrency'] + 1 + DB_POOL_HEADROOM)
```

By default:

- The number of Sidekiq processes is `1`.
- `sidekiq['concurrency']` is `20`.
- `DB_POOL_HEADROOM` is `10`.

Default calculation: 1 Sidekiq process × (20 concurrency + 1 + 10 headroom), for a total of 31 total Sidekiq connections.

### Geo Log Cursor (Geo installations only)

The [Geo Log Cursor](../../development/geo.md#geo-log-cursor-daemon) daemon runs on all GitLab Rails nodes in a secondary site.

```plaintext
Geo log cursor connections = 1 + DB_POOL_HEADROOM
```

Default calculation: 1 + 10 headroom, for a total of 11 Geo connections.

### Total connection requirements

For single node installations:

```plaintext
Total connections = 2 × (Puma + Sidekiq + Geo)
```

For multi-node installations, multiply by the number of nodes running each component:

```plaintext
Total connections = 2 × ((Puma × Rails nodes) + (Sidekiq × Sidekiq nodes) + (Geo × secondary Rails nodes))
```

Multiplying by 2 accounts for the
[dual database connections](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections).

For Geo installations:

- Primary site: Use `Geo = 0`. Geo Log Cursor doesn't run on primary sites.
- Secondary sites: Calculate the Geo Log Cursor database connections for one secondary site, and
  apply that same calculation to all secondary sites.
- Each Geo site connects to its own database, so you don't need to sum connections across multiple Geo sites.
- Set `max_connections` to the same value on both the primary PostgreSQL database and all replica databases,
  using the highest connection requirement across all Geo sites.

### Examples

#### Single node installation

This example is based on the GitLab reference architecture for
[20 RPS (requests per second) or 1000 users](../reference_architectures/1k_users.md):

| Component | Nodes | Configuration             | Connections per component | Component total, dual database |
|-----------|-------|---------------------------|---------------------------|---------------------------------|
| Puma      | 1     | 8 workers, 4 threads each | 14 per worker             | 224                             |
| Sidekiq   | 1     | 1 process, 20 concurrency | 31 per process            | 62                              |
| Total     |       |                           |                           | 286                             |

#### Multi-node installation

This example is based on the GitLab reference architecture for
[40 RPS (requests per second) or 2000 users](../reference_architectures/2k_users.md):

| Component | Nodes | Configuration                      | Connections per component | Component total, dual database |
|-----------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma      | 2     | 8 workers per node, 4 threads each | 14 per worker             | 448                            |
| Sidekiq   | 1     | 4 processes, 20 concurrency each   | 31 per process            | 248                            |
| Total     |       |                                    |                           | 696                            |

#### Single node installation with Geo

This example is based on the GitLab reference architecture for
[20 RPS (requests per second) or 1000 users](../reference_architectures/1k_users.md).

| Component per Geo site                | Nodes | Configuration             | Connections per component | Component total, dual database |
|---------------------------------------|-------|---------------------------|---------------------------|--------------------------------|
| Puma                                  | 1     | 8 workers, 4 threads each | 14 per worker             | 224                            |
| Sidekiq                               | 1     | 1 process, 20 concurrency | 31 per process            | 62                             |
| Geo Log Cursor (secondary sites only) | 1     | 1 process                 | 11 per process            | 22                             |
| Total                                 |       |                           |                           | 308                            |

#### Multi-node installation with Geo

This example is based on the GitLab reference architecture for
[40 RPS (requests per second) or 2000 users](../reference_architectures/2k_users.md):

| Component per Geo site                | Nodes | Configuration                      | Connections per component | Component total, dual database |
|---------------------------------------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma                                  | 2     | 8 workers per node, 4 threads each | 14 per worker             | 448                            |
| Sidekiq                               | 1     | 4 processes, 20 concurrency each   | 31 per process            | 248                            |
| Geo Log Cursor (secondary sites only) | 2     | 1 process per Rails node           | 11 per process            | 44                             |
| Total                                 |       |                                    |                           | 740                            |

## Determine your database host capacity (`max_connections`)

`max_connections` is bounded by what the database host can actually serve - a function of CPU, memory,
and IO capacity. It is not derived from the application connection-demand formula.

- As a general rule, set `max_connections` to a multiple of the number of vCPUs, typically in the 2-10x range. This is only a starting
  point: the value the host can sustain also depends on available memory, IO capacity, and workload.
- For finer tuning, use [PGTune](https://pgtune.leopard.in.ua/), which accounts for memory, storage
  type, and workload.
- If you use a managed PostgreSQL database (RDS, Cloud SQL, Azure Database for PostgreSQL), refer to the
  vendor's documentation.
- Changing the `max_connections` value requires restarting all PostgreSQL nodes.

For Geo installations, set `max_connections` to the same value on the primary PostgreSQL database and
all replica databases. See [Total connection requirements](#total-connection-requirements) for the
Geo-specific guidance.

## Size connections for your topology

Use the following guidance based on whether PgBouncer sits between the application and the database.

### Without PgBouncer

The application connects directly to PostgreSQL, so every connection in the demand calculation must
be served by a backend.

1. Calculate total frontend connection demand using the
   [Plan your database connections](#plan-your-database-connections) formula.
1. Set PostgreSQL `max_connections` to at least that value, provided the host can serve it.
   See [Determine your database host capacity](#determine-your-database-host-capacity-max_connections).
1. If total connection demand exceeds what the host can serve - as a rough guide, when it pushes past
   the 2-10x vCPU range, or drives CPU, memory, or IO past a healthy level - do not raise
   `max_connections` to match. This is a clear sign the installation needs connection pooling.
   Add PgBouncer and size it as described in [With PgBouncer](#with-pgbouncer).

### With PgBouncer

PgBouncer pools connections, so the application's frontend demand and the database's backend
connections are sized separately.

In PgBouncer terminology:

- `pgbouncer['max_client_conn']` is the frontend pool: connections from Rails to PgBouncer.
- `pgbouncer['default_pool_size']` is the backend pool: connections from PgBouncer to the database.
  This value is sized per pool (per database/user pair). Because GitLab opens
  separate pools for `main` and `ci`, the backend pool budget must account for both pools per
  PgBouncer node.

To size connections when using PgBouncer:

1. Calculate your worst-case frontend connection demand using the
   [Plan your database connections](#plan-your-database-connections) formula.
1. Divide that total by the number of PgBouncer nodes, and use the result multiplied by 2 for each
   node's `pgbouncer['max_client_conn']`.
1. Determine PostgreSQL `max_connections` from
   [what the database host can serve](#determine-your-database-host-capacity-max_connections),
   not from the frontend demand formula.
1. Divide that `max_connections` value by the number of PgBouncer nodes, and use the result for
   each node's `pgbouncer['default_pool_size']`.

For detailed reference on these parameters, see [Fine tuning](pgbouncer.md#fine-tuning) in the
PgBouncer documentation.
