---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Guidance for using managed cloud services for GitLab components.
title: Use cloud services for GitLab components
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Instead of managing PostgreSQL, Redis/Valkey, and object storage yourself, you can use managed
cloud provider services for them.

> [!note]
> For cloud-native deployments using the GitLab Helm chart, external PostgreSQL and Redis/Valkey
> services are required. These components are not bundled in the chart.

## Use managed cloud PostgreSQL

Use an external PostgreSQL service running a [supported version](requirements.md#postgresql).
For setup instructions, see
[using an external PostgreSQL database](../administration/postgresql/external.md).

Only full PostgreSQL deployments are supported. Services that implement the PostgreSQL wire protocol
but are not full PostgreSQL deployments, such as [Amazon Aurora](https://aws.amazon.com/rds/aurora/)
and [Google AlloyDB](https://cloud.google.com/alloydb), are incompatible with GitLab.

Services known to work include:

- [Google Cloud SQL](https://cloud.google.com/sql/docs/postgres/high-availability#normal)
- [Amazon RDS](https://aws.amazon.com/rds/)
- [Azure Database for PostgreSQL Flexible Server](https://azure.microsoft.com/en-gb/products/postgresql/)

### Performance and high availability

For larger environments, enable
[database load balancing](../administration/postgresql/database_load_balancing.md) with read replicas.
Match replica counts to those used in equivalent Linux package deployments.
When using read replicas, ensure all replica nodes have `hot_standby_feedback = on` to prevent
replication lag buildup.

For GCP Cloud SQL in larger environments, use the
[Enterprise Plus edition](https://cloud.google.com/sql/docs/editions-intro) for optimal performance.

> [!note]
> GCP Cloud SQL does not support `statement_timeout` as a database flag. Set it per database or user
> instead: `ALTER DATABASE gitlab SET statement_timeout = '60s';`

### GitLab Geo

[GitLab Geo](../administration/geo/_index.md) requires cross-region PostgreSQL replication between
the primary and secondary sites. Not all managed database services support this.

Known limitations:

- Amazon RDS Multi-AZ DB cluster: cross-region replication is not supported. Use a standard
  [RDS Multi-AZ DB instance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZSingleStandby.html)
  with a cross-region read replica instead.
- GCP Cloud SQL: read replicas for Geo can only be created within the same VPC and the same GCP
  project. For secondary sites in a different project, Cloud SQL cannot create the replica directly.
  Configure [PostgreSQL logical replication manually](https://cloud.google.com/sql/docs/postgres/replication/configure-external-replica)
  and then follow the [GitLab Geo external PostgreSQL setup](../administration/geo/setup/external_database.md).

### Connection pooling

If your workload requires additional connection pooling beyond what PostgreSQL handles directly,
deploy your own PgBouncer instance.

> [!note]
> The GitLab-bundled PgBouncer only works with the bundled PostgreSQL and cannot be used with
> external database services.

The following provider-managed pooling solutions are not recommended:

- AWS RDS Proxy: not validated for use with GitLab.
- Azure Database for PostgreSQL PgBouncer: single-threaded with limited observability.
  Can cause bottlenecks under load.

## Use managed cloud Redis and Valkey

Use an external Redis or Valkey service running a [supported version](requirements.md#redis-or-valkey).
For setup instructions, see
[Redis as a managed service](../administration/redis/replication_and_failover_external.md#redis-as-a-managed-service-in-a-cloud-provider).

The service must support:

- Standalone (primary with replica) mode, not Redis Cluster mode
- High availability through replication
- A configurable [eviction policy](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy)

> [!note]
> Serverless Redis and Valkey variants are not supported.

Services known to work include:

- [Google Memorystore](https://cloud.google.com/memorystore)
- [Amazon ElastiCache for Valkey](https://aws.amazon.com/elasticache/valkey/)

> [!note]
> On AWS, use ElastiCache for Valkey 7.2. ElastiCache for Redis 7.2 is not available on AWS.
> ElastiCache for Redis 7.1 is built on Redis 7.0 OSS and is not recommended for new deployments.
> Neither [Azure Cache for Redis](https://azure.microsoft.com/en-gb/products/cache) nor
> [Azure Managed Redis](https://azure.microsoft.com/en-gb/products/managed-redis) currently offer
> Redis 7.2 or a supported Valkey version. For Azure deployments, self-manage Redis or Valkey on
> a virtual machine.

For larger environments, run separate Redis instances for cache and persistent data. Redis is
single-threaded and a single shared instance becomes a bottleneck at scale.

## Use managed cloud object storage

Use any S3-compatible object storage service.
For the full list of tested providers and configuration details, see
[object storage](../administration/object_storage.md).
