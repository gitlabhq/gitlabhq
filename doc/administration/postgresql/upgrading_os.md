---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrading operating systems for PostgreSQL
---

WARNING:
[Geo](../geo/_index.md) cannot be used to migrate a PostgreSQL database from one operating system to another. If you attempt to do so, the secondary site may appear to be 100% replicated when in fact some data is not replicated, leading to data loss. This is because Geo depends on PostgreSQL streaming replication, which suffers from the limitations described in this document. Also see [Geo Troubleshooting - Check OS locale data compatibility](../geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility).

If you upgrade the operating system on which PostgreSQL runs, any
[changes to locale data might corrupt your database indexes](https://wiki.postgresql.org/wiki/Locale_data_changes).
In particular, the upgrade to `glibc` 2.28 is likely to cause this problem. To avoid this issue,
migrate using one of the following options, roughly in order of complexity:

- Recommended. [Backup and restore](#backup-and-restore).
- Recommended. [Rebuild all indexes](#rebuild-all-indexes).
- [Rebuild only affected indexes](#rebuild-only-affected-indexes).

Be sure to backup before attempting any migration, and validate the migration process in a
production-like environment. If the length of downtime might be a problem, then consider timing
different approaches with a copy of production data in a production-like environment.

If you are running a scaled-out GitLab environment, and there are no other services running on the
nodes where PostgreSQL is running, then we recommend upgrading the operating system of the
PostgreSQL nodes by themselves. To reduce complexity and risk, do not combine the procedure with
other changes, especially if those changes do not require downtime, such as upgrading the operating
system of nodes running only Puma or Sidekiq.

For more information about how GitLab plans to address this issue, see
[epic 8573](https://gitlab.com/groups/gitlab-org/-/epics/8573).

## Backup and restore

Backup and restore recreates the entire database, including the indexes.

1. Take a scheduled downtime window. In all nodes, stop unnecessary GitLab services:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. Backup the PostgreSQL database with `pg_dump` or the
   [GitLab backup tool, with all data types except `db` excluded](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)
   (so only the database is backed up).
1. In all PostgreSQL nodes, upgrade the OS.
1. In all PostgreSQL nodes,
   [update GitLab package sources after upgrading the OS](../package_information/supported_os.md#update-gitlab-package-sources-after-upgrading-the-os).
1. In all PostgreSQL nodes, install the new GitLab package of the same GitLab version.
1. Restore the PostgreSQL database from backup.
1. In all nodes, start GitLab.

**Advantages**:

- Straightforward.
- Removes any database bloat in indexes and tables, reducing disk use.

**Disadvantages**:

- Downtime increases with database size, at some point becoming problematic. It depends on many
  factors, but if your database is over 100 GB then it might take on the order of 24 hours.

### Backup and restore, with Geo secondary sites

1. Take a scheduled downtime window. In all nodes of all sites, stop unnecessary GitLab services:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. In the primary site, backup the PostgreSQL database with `pg_dump` or the
   [GitLab backup tool, with all data types except `db` excluded](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)
   (so only the database is backed up).
1. In all PostgreSQL nodes of all sites, upgrade the OS.
1. In all PostgreSQL nodes of all sites,
   [update GitLab package sources after upgrading the OS](../package_information/supported_os.md#update-gitlab-package-sources-after-upgrading-the-os).
1. In all PostgreSQL nodes of all sites, install the new GitLab package of the same GitLab version.
1. In the primary site, restore the PostgreSQL database from backup.
1. Optionally, start using the primary site, at the risk of not having a secondary site as warm
   standby.
1. Set up PostgreSQL streaming replication to the secondary sites again.
1. If the secondary sites receive traffic from users, then let the read-replica databases catch up
   before starting GitLab.
1. In all nodes of all sites, start GitLab.

## Rebuild all indexes

[Rebuild all indexes](https://www.postgresql.org/docs/14/sql-reindex.html).

1. Take a scheduled downtime window. In all nodes, stop unnecessary GitLab services:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. In all PostgreSQL nodes, upgrade the OS.
1. In all PostgreSQL nodes,
   [update GitLab package sources after upgrading the OS](../package_information/supported_os.md#update-gitlab-package-sources-after-upgrading-the-os).
1. In all PostgreSQL nodes, install the new GitLab package of the same GitLab version.
1. In a [database console](../troubleshooting/postgresql.md#start-a-database-console), rebuild all indexes:

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. After reindexing the database, the version must be refreshed for all affected collations.
   To update the system catalog to record the current collation version:

   ```sql
   ALTER COLLATION <collation_name> REFRESH VERSION;
   ```

1. In all nodes, start GitLab.

**Advantages**:

- Straightforward.
- May be faster than backup and restore, depending on many factors.
- Removes any database bloat in indexes, reducing disk use.

**Disadvantages**:

- Downtime increases with database size, at some point becoming problematic.

### Rebuild all indexes, with Geo secondary sites

1. Take a scheduled downtime window. In all nodes of all sites, stop unnecessary GitLab services:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. In all PostgreSQL nodes, upgrade the OS.
1. In all PostgreSQL nodes,
   [update GitLab package sources after upgrading the OS](../package_information/supported_os.md#update-gitlab-package-sources-after-upgrading-the-os).
1. In all PostgreSQL nodes, install the new GitLab package of the same GitLab version.
1. In the primary site, in a
   [database console](../troubleshooting/postgresql.md#start-a-database-console), rebuild all indexes:

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. After reindexing the database, the version must be refreshed for all affected collations.
   To update the system catalog to record the current collation version:

   ```sql
   ALTER COLLATION <collation_name> REFRESH VERSION;
   ```

1. If the secondary sites receive traffic from users, then let the read-replica databases catch up
   before starting GitLab.
1. In all nodes of all sites, start GitLab.

## Rebuild only affected indexes

This is similar to the approach used for GitLab.com. To learn more about this process and how the
different types of indexes were handled, see the blog post about
[upgrading the operating system on our PostgreSQL database clusters](https://about.gitlab.com/blog/2022/08/12/upgrading-database-os/).

1. Take a scheduled downtime window. In all nodes, stop unnecessary GitLab services:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. In all PostgreSQL nodes, upgrade the OS.
1. In all PostgreSQL nodes,
   [update GitLab package sources after upgrading the OS](../package_information/supported_os.md#update-gitlab-package-sources-after-upgrading-the-os).
1. In all PostgreSQL nodes, install the new GitLab package of the same GitLab version.
1. [Determine which indexes are affected](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected).
1. In a [database console](../troubleshooting/postgresql.md#start-a-database-console), reindex each affected index:

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. After reindexing bad indexes, the collation must be refreshed. To update the system catalog to
   record the current collation version:

   ```sql
   ALTER COLLATION <collation_name> REFRESH VERSION;
   ```

1. In all nodes, start GitLab.

**Advantages**:

- Downtime is not spent rebuilding unaffected indexes.

**Disadvantages**:

- More chances for mistakes.
- Requires expert knowledge of PostgreSQL to handle unexpected problems during migration.
- Preserves database bloat.

### Rebuild only affected indexes, with Geo secondary sites

1. Take a scheduled downtime window. In all nodes of all sites, stop unnecessary GitLab services:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. In all PostgreSQL nodes, upgrade the OS.
1. In all PostgreSQL nodes,
   [update GitLab package sources after upgrading the OS](../package_information/supported_os.md#update-gitlab-package-sources-after-upgrading-the-os).
1. In all PostgreSQL nodes, install the new GitLab package of the same GitLab version.
1. [Determine which indexes are affected](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected).
1. In the primary site, in a
   [database console](../troubleshooting/postgresql.md#start-a-database-console), reindex each affected index:

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. After reindexing bad indexes, the collation must be refreshed. To update the system catalog to
   record the current collation version:

   ```sql
   ALTER COLLATION <collation_name> REFRESH VERSION;
   ```

1. The existing PostgreSQL streaming replication should replicate the reindex changes to the
   read-replica databases.
1. In all nodes of all sites, start GitLab.

## Checking `glibc` versions

To see what version of `glibc` is used, run `ldd --version`.

The following table shows the `glibc` versions shipped for different operating systems:

| Operating system    | `glibc` version |
|---------------------|-----------------|
| CentOS 7            | 2.17            |
| RedHat Enterprise 8 | 2.28            |
| RedHat Enterprise 9 | 2.34            |
| Ubuntu 18.04        | 2.27            |
| Ubuntu 20.04        | 2.31            |
| Ubuntu 22.04        | 2.35            |
| Ubuntu 24.04        | 2.39            |

For example, suppose you are upgrading from CentOS 7 to RedHat
Enterprise 8. In this case, using PostgreSQL on this upgraded operating
system requires using one of the two mentioned approaches, because `glibc`
is upgraded from 2.17 to 2.28. Failing to handle the collation changes
properly causes significant failures in GitLab, such as runners not
picking jobs with tags.

On the other hand, if PostgreSQL has already been running on `glibc` 2.28
or higher with no issues, your indexes should continue to work without
further action. For example, if you have been running PostgreSQL on
RedHat Enterprise 8 (`glibc` 2.28) for a while, and want to upgrade
to RedHat Enterprise 9 (`glibc` 2.34), there should be no collations-related issues.

### Verifying `glibc` collation versions

For PostgreSQL 13 and higher, you can verify that your database
collation version matches your system with this SQL query:

```sql
SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
```

### Matching collation example

For example, on a Ubuntu 22.04 system, the output of a properly indexed
system looks like:

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.35    | 2.35
 en_US          | 2.35    | 2.35
(6 rows)
```

### Mismatched collation example

On the other hand, if you've upgraded from Ubuntu 18.04 to 22.04 without
reindexing, you might see:

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.27    | 2.35
 en_US          | 2.27    | 2.35
(6 rows)
```

## Streaming replication

The corrupted index issue affects PostgreSQL streaming replication. You must
[rebuild all indexes](#rebuild-all-indexes) or
[rebuild only affected indexes](#rebuild-only-affected-indexes) before allowing
reads against a replica with different locale data.

## Additional Geo variations

The above upgrade procedures are not set in stone. With Geo there are potentially more options,
because there exists redundant infrastructure. You could consider modifications to suit your use-case,
but be sure to weigh it against the added complexity. Here are some examples:

To reserve a secondary site as a warm standby in case of disaster during the OS upgrade of the
primary site and the other secondary site:

1. Isolate the secondary site's data from changes on the primary site: Pause the secondary site.
1. Perform the OS upgrade on the primary site.
1. If the OS upgrade fails and the primary site is unrecoverable, then promote the secondary site,
1. route users to it, and try again later.
1. Note that this leaves you without an up-to-date secondary site.

To provide users with read-only access to GitLab during the OS upgrade (partial downtime):

1. Enable [Maintenance Mode](../maintenance_mode/_index.md) on the primary site instead of stopping
   it.
1. Promote the secondary site but do not route users to it yet.
1. Perform the OS upgrade on the promoted site.
1. Route users to the promoted site instead of the old primary site.
1. Set up the old primary site as a new secondary site.

WARNING:
Even though the secondary site already has a read-replica of the database, you cannot upgrade
its operating system prior to promotion. If you were to attempt that, then the secondary site may
miss replication of some Git repositories or files, due to the corrupted indexes.
See [Streaming replication](#streaming-replication).
