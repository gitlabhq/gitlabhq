---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Introduction to ClickHouse use and table design

## How it differs from PostgreSQL

The [intro](https://clickhouse.com/docs/en/intro/) page is quite good to give an overview of ClickHouse.

ClickHouse has a lot of differences from traditional OLTP (online transaction processing) databases like PostgreSQL. The underlying architecture is a bit different, and the processing is a lot more CPU-bound than in traditional databases.
ClickHouse is a log-centric database where immutability is a key component. The advantages of such approaches are well documented [[1]](https://www.odbms.org/2015/10/the-rise-of-immutable-data-stores/) however it also makes updates much harder. See ClickHouse [documentation](https://clickhouse.com/docs/en/guides/developer/mutations/) for operations that provide UPDATE/DELETE support. It is noticeable that these operations are supposed to be non-frequent.

This distinction is important while designing tables. Either:

- The updates are not required (best case)
- If they are needed, they aren't to be run during query execution.

## ACID compatibility

ClickHouse has a slightly different overview of Transactional support, where the guarantees are applicable only up to a block of inserted data to a specific table. See [the Transactional (ACID) support](https://clickhouse.com/docs/en/guides/developer/transactional/) documentation for details.

Multiple insertions in a single write should be avoided as transactional support across multiple tables is only covered in materialized views.

ClickHouse is heavily geared towards providing the best-in-class support for analytical queries. Operations like aggregation are very fast and there are several features to augment these capabilities.
ClickHouse has some good blog posts covering [details of aggregations](https://altinity.com/blog/clickhouse-aggregation-fun-part-1-internals-and-handy-tools).

## Primary indexes, sorting index and dictionaries

It is highly recommended to read ["A practical introduction to primary indexes in ClickHouse""](https://clickhouse.com/docs/en/guides/improving-query-performance/sparse-primary-indexes/sparse-primary-indexes-intro) to get an understanding of indexes in ClickHouse.

Particularly how database index design in ClickHouse [differs](https://clickhouse.com/docs/en/guides/improving-query-performance/sparse-primary-indexes/sparse-primary-indexes-design/#an-index-design-for-massive-data-scales) from those in transactional databases like PostgreSQL.

Primary index design plays a very important role in query performance and should be stated carefully. Almost all of the queries should rely on the primary index as full data scans are bound to take longer.

Read the documentation for [primary keys and indexes in queries](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree/#primary-keys-and-indexes-in-queries) to learn how indexes can affect query performance in MergeTree Table engines (default table engine in ClickHouse).

Secondary indexes in ClickHouse are different from what is available in other systems. They are also called data-skipping indexes as they are used to skip over a block of data. See the documentation for [data-skipping indexes](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#table_engine-mergetree-data_skipping-indexes).

ClickHouse also offers ["Dictionaries"](https://clickhouse.com/docs/en/sql-reference/dictionaries/external-dictionaries/external-dicts/) which can be used as external indexes. Dictionaries are loaded from memory and can be used to look up values on query runtime.

## Data types & Partitioning

ClickHouse offers SQL-compatible [data types](https://clickhouse.com/docs/en/sql-reference/data-types/) and few specialized data types like:

- [`LowCardinality`](https://clickhouse.com/docs/en/sql-reference/data-types/lowcardinality)
- [UUID](https://clickhouse.com/docs/en/sql-reference/data-types/uuid)
- [Maps](https://clickhouse.com/docs/en/sql-reference/data-types/map)
- [Nested](https://clickhouse.com/docs/en/sql-reference/data-types/nested-data-structures/nested) which is interesting, because it simulates a table inside a column.

One key design aspect that comes up front while designing a table is the partitioning key. Partitions can be any arbitrary expression but usually, these are time duration like months, days, or weeks. ClickHouse takes a best-effort approach to minimize the data read by using the smallest set of partitions.

Suggested reads:

- [Choose a low cardinality partitioning key](https://clickhouse.com/docs/en/optimize/partitioning-key)
- [Custom partitioning key](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/custom-partitioning-key).

## Sharding and replication

Sharding is a feature that allows splitting the data into multiple ClickHouse nodes to increase throughput and decrease latency. The sharding feature uses a distributed engine that is backed by local tables. The distributed engine is a "virtual" table that does not store any data. It is used as an interface to insert and query data.

See [the ClickHouse documentation](https://clickhouse.com/docs/en/engines/table-engines/special/distributed/) and this section on [replication and sharding](https://clickhouse.com/docs/en/manage/replication-and-sharding/). ClickHouse can use either Zookeeper or its own compatible API via a component called [ClickHouse Keeper](https://clickhouse.com/docs/en/operations/clickhouse-keeper) to maintain consensus.

After nodes are set up, they can become invisible from the Clients and both write and read queries can be issued to any node.

In most cases, clusters usually start with a fixed number of nodes(~ shards). [Rebalancing shards](https://clickhouse.com/docs/en/guides/sre/scaling-clusters) is operationally heavy and requires rigorous testing.

Replication is supported by MergeTree Table engine, see the [replication section](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/replication/) in documentation for details on how to define them.
ClickHouse relies on a distributed coordination component (either Zookeeper or ClickHouse Keeper) to track the participating nodes in the quorum. Replication is asynchronous and multi-leader. Inserts can be issued to any node and they can appear on other nodes with some latency. If desired, stickiness to a specific node can be used to make sure that reads observe the latest written data.

## Materialized views

One of the defining features of ClickHouse is materialized views. Functionally they resemble insert triggers for ClickHouse.
Materialized views can be used for a variety of use cases which are well [documented](https://www.polyscale.ai/blog/polyscale-metrics-materialized-views/) on the web.

We recommended reading the [views](https://clickhouse.com/docs/en/sql-reference/statements/create/view#materialized-view) section from the official documentation to get a better understanding of how they work.

Quoting the [documentation](https://clickhouse.com/docs/en/sql-reference/statements/create/view#materialized-view):

> Materialized views in ClickHouse are implemented more like insert triggers.
> If there's some aggregation in the view query, it's applied only to the batch
> of freshly inserted data. Any changes to existing data of the source table
> (like update, delete, drop a partition, etc.) do not change the materialized view.
