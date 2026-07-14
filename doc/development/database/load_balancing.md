---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Database load balancing
---

With database load balancing, read-only queries are distributed across multiple PostgreSQL nodes.
For configuration and administration, see
[database load balancing](../../administration/postgresql/database_load_balancing.md).

## Nomenclature

| Term | Definition |
|---|---|
| Host | A database host. Can be a primary or a replica. |
| Primary | The primary PostgreSQL host, used for all write operations and read-write transactions. |
| Replica | A secondary PostgreSQL host, used for read-only queries. |
| Workload | A Rails request or Sidekiq job that requires database connections. |
| Sticking | The behavior of routing a workload to the primary after a write, until replicas catch up. |

## Key classes

All load balancing classes are in the `Gitlab::Database::LoadBalancing` namespace:

| Class | Responsibility |
|---|---|
| `ConnectionProxy` | Intercepts `ActiveRecord` connection requests and routes them to `LoadBalancer`. |
| `LoadBalancer` | Selects a host (primary or replica) and yields a connection from its pool. |
| `Host` | Represents a single database host. Tracks online status and replication lag. |
| `Session` | Tracks per-workload database state: whether a write has occurred, whether the workload is stuck to the primary. |
| `SessionMap` | Maps each load-balanced database to its own `Session` instance within a workload. |
| `Sticking` | Manages primary sticking state in Redis, keyed by namespace and ID. |

## Query routing

Each workload begins with a fresh `Session` instance per load-balanced database. The `Session`
tracks all database operations for that workload and determines whether connections should go to
the primary or a replica.

When `ActiveRecord` requests a connection, `ConnectionProxy` evaluates the following in order:

1. Is the operation a write (insert, update, delete)? Route to primary, mark session as written.
1. Is the session already stuck to the primary (due to a prior write)? Route to primary.
1. Is the query a `SELECT ... FOR UPDATE` or similar locking read? Route to primary.
1. Is a `use_primary` block active? Route to primary.
1. Otherwise: route to a replica.

### Special routing blocks

The following blocks override default routing behavior:

| Block | Effect |
|---|---|
| `use_primary` | Forces all queries in the block to the primary. |
| `use_primary!` | Sticks the current session to the primary for the remainder of the workload. |
| `ignore_writes` | Performs writes on the primary but does not trigger primary sticking. |
| `use_replicas_for_read_queries` | Forces reads to replicas even when the session is stuck to the primary. |
| `fallback_to_replicas_for_ambiguous_queries` | Allows transactions and ambiguous queries to use replicas when no write has occurred. |

### Transactions

By default, transactions route to the primary. When `fallback_to_replicas_for_ambiguous_queries`
is active, a transaction can use replicas as long as no write has been performed within it.
Any write inside the transaction routes to the primary and triggers sticking.

Writes inside a block marked as `use_replicas_for_read_queries` raise
`WriteInsideReadOnlyTransactionError`.

## Primary sticking

After a write, GitLab sticks the workload to the primary until replicas have caught up. Sticking
is tracked in Redis using PostgreSQL LSN (Log Sequence Number) positions, not just a timeout.

### Sticking scope

Sticking is scoped by `(namespace, id)` pairs. For web requests, `namespace` is `:user` and `id`
is the current user ID. Multiple namespaces can be stuck simultaneously and are tracked
independently. See `Sticking#sticking_key` in
`lib/gitlab/database/load_balancing/sticking.rb` for the Redis key format.

For sensitive identifiers such as API tokens or session tokens, pass `hash_id: true` to the
sticking methods. This stores a SHA-256 hash of the ID instead of the raw value:

```ruby
Gitlab::Database::LoadBalancing::Sticking.stick(:api_key, token, hash_id: true)
```

### Release mechanism

The stick is released when any of the following occurs:

- A replica's LSN reaches or passes the recorded write LSN. GitLab unsticks immediately rather
  than waiting for the full 30-second timeout.
- The 30-second expiry is reached, regardless of replication state.

LSN comparisons use atomic Lua scripts in Redis to avoid race conditions between concurrent
requests from the same user.

### Sidekiq sticking

Sidekiq uses a WAL-based approach to avoid stale reads in background jobs:

1. **On enqueue** (`SidekiqClientMiddleware`): the current LSN for each load-balanced database is
   recorded in the job payload, along with whether the LSN came from the primary or a replica.
1. **On execution** (`SidekiqServerMiddleware`): before the job runs, GitLab checks whether a
   replica has caught up to the recorded LSN.
   - High-urgency workers: up to 5 attempts over 0.5 seconds.
   - Regular workers: up to 3 attempts over 1.5 seconds.
   - If no replica catches up in time, the job falls back to reading from the primary.

## Replica lag checking

Before routing a read to a replica, `LoadBalancer` checks whether the replica is sufficiently
in sync with the primary.

### Check interval

Lag checks run at randomized intervals between `replica_check_interval` and
`2 * replica_check_interval` seconds. The interval is randomized per process to spread health
check load.

### Two-tier lag evaluation

The check uses two methods in sequence:

1. **Time-based**: compares `pg_last_wal_replay_lsn()` against the primary's current LSN. If the
   replica lags by more than `max_replication_lag_time` seconds, it is skipped.
1. **Data size fallback**: if the time-based check cannot determine lag (for example, because the
   primary has had no recent writes), GitLab falls back to comparing byte-level LSN difference
   against `max_replication_difference`. This prevents replicas from being incorrectly marked
   offline during low-write periods.

### Logical replicas

For logical replicas, GitLab uses `pg_replication_origin_status` to determine replication lag
instead of `pg_last_wal_replay_lsn`. GitLab detects logical replicas automatically when the
querying user has `SELECT` privileges on `pg_replication_origin_status`.
PostgreSQL 14 or later is required for logical replica detection.

### Feature flags

The following feature flags affect replica lag behavior at runtime:

| Flag | Effect |
|---|---|
| `load_balancer_ignore_replication_lag_time` | Disables time-based lag checking entirely. |
| `load_balancer_double_replication_lag_time` | Allows up to 2x the configured `max_replication_lag_time`. |
| `load_balancer_low_statement_timeout` | Uses a 100ms statement timeout for health check queries to limit overhead. |

## Failover handling

The load balancer handles failures differently depending on whether the failed operation was a read
or a write.

### Read failover

When a read fails due to a connection error, `LoadBalancer` marks the host as offline and retries
with the next available replica. If all replicas are offline, the read falls back to the primary.

When a read fails due to a query conflict (serialization failure), `LoadBalancer` retries across
all replicas up to `host_list.length * 3` times before falling back to the primary.

The `load_balancer_force_release_hosts` feature flag forces connections to be released from all
hosts rather than only the current one, which can help in certain failover scenarios.

### Write failover

Write retries depend on transaction state:

- **Outside an open transaction**: retries up to 3 times with exponential back-off (2s, 4s, 8s).
- **Inside an open transaction**: no retry. The transaction cannot be safely replayed, so the
  error is surfaced immediately.

## Service discovery

When using service discovery, `LoadBalancer` periodically resolves the configured DNS record to
get the current list of replica addresses. The list is updated when the DNS response changes or
when `disconnect_timeout` is reached for stale connections.

### `max_replica_pools`

When `max_replica_pools` is set, the `Sampler` class limits how many replicas each GitLab process
connects to. This only applies to service discovery - static host lists always connect to all
configured hosts.

The sampler selects replicas deterministically per process using a consistent seed, distributing
connections evenly across all returned hostnames. When the replica count exceeds `max_replica_pools`,
the sampler logs which replicas were excluded.

## Write location queries

GitLab uses one of two SQL queries to determine the current write LSN, controlled by the
`USE_NEW_LOAD_BALANCER_QUERY` environment variable (default: `true`). The default query handles
standbys with active replication slots correctly; the legacy query uses
`pg_current_wal_insert_lsn()` unconditionally. See `LoadBalancer#query_for_location` in
`lib/gitlab/database/load_balancing/load_balancer.rb` for the implementation.

Set `USE_NEW_LOAD_BALANCER_QUERY=false` only when diagnosing unexpected LSN behavior on older
PostgreSQL setups.

## Deployment strategy

When rolling out load balancing changes behind a feature flag, deploy to Sidekiq workers first.

Reasons to deploy to Sidekiq first:

- API pods remain stable, keeping ChatOps available to disable the flag if needed.
- Background jobs retry automatically without user impact.

Example:

```ruby
if Feature.enabled?(:my_flag) && Gitlab::Runtime.sidekiq?
  new_changes
else
  existing_changes
end
```
