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
| `max_connections`      | minimum `400`   | Calculate based on your GitLab components. See [Plan your database connections](#plan-your-database-connections) for detailed guidance. |
| `shared_buffers`       | minimum `2 GB`  | You require more for larger database servers. The Linux package default is set to 25% of server RAM. |
| `statement_timeout`    | 15000 to 60000 | A statement timeout prevents runaway issues with locks and the database rejecting new clients. You should use values between 15 and 60 seconds (15000 to 60000 milliseconds), where one minute matches the Puma rack timeout setting. |
| `hot_standby_feedback` | `on` | For configurations with multiple nodes and [database load balancing](database_load_balancing.md#configure-database-load-balancing) configured, ensure that all replica nodes have `hot_standby_feedback` enabled to prevent lag buildup. |

You can configure some PostgreSQL settings for the specific database, rather than for all databases on the server.

- You might limit configuration to specific databases when hosting multiple databases on the same server.
- For guidance on where to apply configuration, consult your database administrator or vendor.
- For GCP Cloud SQL, you can set `statement_timeout` on a specific database or user, but not [as a database flag](https://cloud.google.com/sql/docs/postgres/flags#list-flags-postgres).
  For example: `ALTER DATABASE gitlab SET statement_timeout = '60s';`

## Plan your database connections

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
[dual database connections](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections) in GitLab 16.0 and later.

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
