---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrading operating systems for PostgreSQL

If you upgrade the operating system on which PostgreSQL runs,
an upgrade of [locale data changes in `glibc` 2.28](https://wiki.postgresql.org/wiki/Locale_data_changes) might corrupt your database indexes.
To avoid this issue, migrate using either:

- Recommended. [Backup and restore](#backup-and-restore).
- [Replication and failover, with an index rebuild](#replication-and-failover).

For more information about how GitLab plans to address this issue, see
[epic 8573](https://gitlab.com/groups/gitlab-org/-/epics/8573).

## Backup and restore

Use `pg_dump` or the [GitLab backup tool, with all data types except `db` excluded](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)
(so only the database is backed up).

The restore recreates the entire database, including the indexes.

**Advantages**:

- Simpler and more straightforward than replication.
- Removes any database bloat in indexes and tables, reducing disk use.

**Disadvantages**:

- Downtime is likely to be longer and particularly problematic for large databases.

## Replication and failover

Set up streaming replication from the old database server to the new server.

As part of the plan to switch to the new server, reindex all [affected indexes](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected):

- In a [database console](../troubleshooting/postgresql.md#start-a-database-console), run
`REINDEX INDEX <index name> CONCURRENTLY` on each index.

This approach was used for GitLab.com. To learn more about this process and how the different types of indexes were handled, see the blog post about [upgrading the operating system on our Postgres database clusters](https://about.gitlab.com/blog/2022/08/12/upgrading-database-os/).

After reindexing bad indexes, the collation must be refreshed.
To update the system catalog to record the current collation version,
run the query `ALTER COLLATION <collation_name> REFRESH VERSION`.

**Advantages**:

- Downtime is shorter: the time to perform the necessary reindexing, plus validation.
- Likely to be faster if database is large.

**Disadvantages**:

- Technically complicated: setting up replication and ensuring all necessary reindexing is completed.
- Preserves database bloat.

## Checking `glibc` versions

To see what version of `glibc` is used, run `ldd --version`.

You can compare the behavior of `glibc` on your servers [using shell commands](../geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility).

The following table shows the `glibc` versions shipped for different operating systems:

|Operating system    |`glibc` version|
|--------------------|-------------|
|CentOS 7            | 2.17 |
|RedHat Enterprise 8 | 2.28 |
|RedHat Enterprise 9 | 2.34 |
|Ubuntu 18.04        | 2.27 |
|Ubuntu 20.04        | 2.31 |
|Ubuntu 22.04        | 2.35 |
|Ubuntu 24.04        | 2.39 |

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
