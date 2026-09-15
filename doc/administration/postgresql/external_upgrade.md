---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Upgrading external PostgreSQL databases
---

When upgrading your PostgreSQL database engine, it is important to follow all steps
recommended by the PostgreSQL community and your cloud provider. Two
kinds of upgrades exist for PostgreSQL databases:

- Minor version upgrades: These include only bug and security fixes. They are
  always backward-compatible with your existing application database model.

  The minor version upgrade process consists of replacing the PostgreSQL binaries
  and restarting the database service. The data directory remains unchanged.

- Major version upgrades: These change the internal storage format and the database
  catalog. As a result, object statistics used by the query optimizer
  [are not transferred to the new version](https://www.postgresql.org/docs/16/pgupgrade.html)
  and must be rebuilt with `ANALYZE`.

  Not following the documented major version upgrade process often results in
  poor database performance and high CPU use on the database server.

All major cloud providers support in-place major version upgrades of database
instances, using the `pg_upgrade` utility. However, you must follow the pre- and
post-upgrade steps to reduce the risk of performance degradation or database disruption.

Read carefully the major version upgrade steps of your external database platform:

- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html#USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process)
- [Azure Database for PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/configure-maintain/concepts-major-version-upgrade)
- [Google Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres/upgrade-major-db-version-inplace)
- [PostgreSQL community `pg_upgrade`](https://www.postgresql.org/docs/16/pgupgrade.html)

> [!note]
> For PostgreSQL upgrades that use logical replication, such as Amazon RDS Blue/Green
> Deployments, disable runtime DDL in GitLab before you start:
>
> ```shell
> sudo gitlab-rails runner "Feature.enable(:disallow_database_ddl_feature_flags)"
> ```
>
> Re-enable it as soon as the upgrade is complete:
>
> ```shell
> sudo gitlab-rails runner "Feature.disable(:disallow_database_ddl_feature_flags)"
> ```
>
> Leaving DDL disabled for more than a few days can degrade performance. Enabling the flag
> also pauses background migrations, so GitLab upgrades fail while the flag is enabled.

## Always `ANALYZE` your database after a major version upgrade

It is mandatory to run the [`ANALYZE` operation](https://www.postgresql.org/docs/16/sql-analyze.html)
to refresh the `pg_statistic` table after a major version upgrade, because optimizer statistics
[are not transferred by `pg_upgrade`](https://www.postgresql.org/docs/16/pgupgrade.html).
This should be done for all databases on the upgraded PostgreSQL service/instance/cluster.

When you plan your maintenance window, you should include the `ANALYZE` duration
because this operation might significantly degrade GitLab performance.

## Restart GitLab after a database upgrade

You must restart GitLab (Sidekiq, Puma, PgBouncer, and Praefect,
where applicable) after any PostgreSQL engine upgrade, minor or major,
because a database service restart invalidates existing connections
and these components might require a restart to reconnect successfully.

When you plan your maintenance window, you should include time to restart
GitLab immediately after the upgrade completes.
