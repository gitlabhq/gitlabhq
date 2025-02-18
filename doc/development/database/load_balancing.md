---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database load balancing
---

With database load balancing, read-only queries can be distributed across multiple
PostgreSQL nodes to increase performance.

This documentation provides a technical overview on how database load balancing
is implemented in GitLab Rails and Sidekiq.

## Nomenclature

1. **Host**: Each database host. It could be a primary or a replica.
1. **Primary**: Primary PostgreSQL host that is used for write-only and read-and-write operations.
1. **Replica**: Secondary PostgreSQL hosts that are used for read-only operations.
1. **Workload**: a Rails request or a Sidekiq job that requires database connections.

## Components

A few Ruby classes are involved in the load balancing process. All of them are
in the namespace `Gitlab::Database::LoadBalancing`:

1. `Host`
1. `LoadBalancer`
1. `ConnectionProxy`
1. `Session`

Each workload begins with a new instance of `Gitlab::Database::LoadBalancing::Session`.
The `Session` keeps track of the database operations that have been performed. It then
determines if the workload requires a connection to either the primary host or a replica host.

When the workload requires a database connection through `ActiveRecord`,
`ConnectionProxy` first redirects the connection request to `LoadBalancer`.
`ConnectionProxy` requests either a `read` or `read_write` connection from the `LoadBalancer`
depending on a few criteria:

1. Whether the query is a read-only or it requires write.
1. Whether the `Session` has recorded a write operation previously.
1. Whether any special blocks have been used to prefer primary or replica, such as:
   - `use_primary`
   - `ignore_writes`
   - `use_replicas_for_read_queries`
   - `fallback_to_replicas_for_ambiguous_queries`

`LoadBalancer` then yields the requested connection from the respective database connection pool.
It yields either:

- A `read_write` connection from the primary's connection pool.
- A `read` connection from the replicas' connection pools.

When responding to a request for a `read` connection, `LoadBalancer` would
first attempt to load balance the connection across the replica hosts.
It looks for the next `online` replica host and yields a connection from the host's connection pool.
A replica host is considered `online` if it is up-to-date with the primary, based on
either the replication lag size or time. The thresholds for these requirements are configurable.
