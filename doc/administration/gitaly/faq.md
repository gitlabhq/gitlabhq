---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Frequently asked questions **(FREE SELF)**

The following are answers to frequently asked questions about Gitaly and Gitaly Cluster. For
troubleshooting information, see [Troubleshooting Gitaly and Gitaly Cluster](troubleshooting.md).

## How does Gitaly Cluster compare to Geo?

Gitaly Cluster and [Geo](../geo/index.md) both provide redundancy. However the redundancy of:

- Gitaly Cluster provides fault tolerance for data storage and is invisible to the user. Users are
  not aware when Gitaly Cluster is used.
- Geo provides [replication](../geo/index.md) and [disaster recovery](../geo/disaster_recovery/index.md) for
  an entire instance of GitLab. Users know when they are using Geo for
  [replication](../geo/index.md). Geo [replicates multiple data types](../geo/replication/datatypes.md#limitations-on-replicationverification),
  including Git data.

The following table outlines the major differences between Gitaly Cluster and Geo:

| Tool           | Nodes    | Locations | Latency tolerance  | Failover                                                                    | Consistency                              | Provides redundancy for |
|:---------------|:---------|:----------|:-------------------|:----------------------------------------------------------------------------|:-----------------------------------------|:------------------------|
| Gitaly Cluster | Multiple | Single    | Approximately 1 ms | [Automatic](praefect.md#automatic-failover-and-primary-election-strategies) | [Strong](index.md#strong-consistency)    | Data storage in Git     |
| Geo            | Multiple | Multiple  | Up to one minute   | [Manual](../geo/disaster_recovery/index.md)                                 | Eventual                                 | Entire GitLab instance  |

For more information, see:

- Geo [use cases](../geo/index.md#use-cases).
- Geo [architecture](../geo/index.md#architecture).

## Are there instructions for migrating to Gitaly Cluster?

Yes! For more information, see [Migrate to Gitaly Cluster](praefect.md#migrate-to-gitaly-cluster).

## What are some repository storage recommendations?

The size of the required storage can vary between instances and depends on the set
[replication factor](index.md#replication-factor). You might want to include implementing
repository storage redundancy.

For a replication factor:

- Of `1`: NFS, Gitaly, and Gitaly Cluster have roughly the same storage requirements.
- More than `1`: The amount of required storage is `used space * replication factor`. `used space`
  should include any planned future growth.

## What are some Praefect database storage requirements?

The requirements are relatively low because the database contains only metadata of:

- Where repositories are located.
- Some queued work.

It depends on the number of repositories, but a useful minimum is 5-10 GB, similar to the main
GitLab application database.

## Can the GitLab application database and the Praefect database be on the same servers?

Yes, however Praefect should have it's own database server when using Omnibus GitLab PostgreSQL. If
there is a failover, Praefect isn't aware and starts to fail as the database it's trying to use would
either:

- Be unavailable.
- In read-only mode.

A future solution may allow for Praefect and Omnibus GitLab databases on the same PostgreSQL server.
For more information, see the relevant:

- [Omnibus GitLab issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5919).
- [Gitaly issue](https://gitlab.com/gitlab-org/gitaly/-/issues/3398).

## Is PgBouncer required for the Praefect database?

No, because the number of connections Praefect makes is low. You can use the same PgBouncer instance
for both the GitLab application database and the Praefect database if you wish.

## Are there any special considerations for Gitaly Cluster when PostgreSQL is upgraded?

There are no special requirements. Gitaly Cluster requires PostgreSQL version 11 or later.

## Praefect database tables are empty?

These tables are created per the [specific configuration section](praefect.md#postgresql).

If you find you have an empty Praefect database table, see the
[relevant troubleshooting section](troubleshooting.md#relation-does-not-exist-errors).
