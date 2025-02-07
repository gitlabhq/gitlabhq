---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Moving GitLab databases to a different PostgreSQL instance
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Sometimes it is necessary to move your databases from one PostgreSQL instance to
another. For example, if you are using AWS Aurora and are preparing to
enable Database Load Balancing, you need to move your databases to
RDS for PostgreSQL.

To move databases from one instance to another:

1. Gather the source and destination PostgreSQL endpoint information:

   ```shell
   SRC_PGHOST=<source postgresql host>
   SRC_PGUSER=<source postgresql user>

   DST_PGHOST=<destination postgresql host>
   DST_PGUSER=<destination postgresql user>
   ```

1. Stop GitLab:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Dump the databases from the source:

   ```shell
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f gitlabhq_production.sql gitlabhq_production
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f praefect_production.sql praefect_production
   ```

   NOTE:
   In rare occasions, you might notice database performance issues after you perform
   a `pg_dump` and restore. This can happen because `pg_dump` does not contain the statistics
   [used by the optimizer to make query planning decisions](https://www.postgresql.org/docs/14/app-pgdump.html).
   If performance degrades after a restore, fix the problem by finding the problematic query,
   then running ANALYZE on the tables used by the query.  

1. Restore the databases to the destination (this overwrites any existing databases with the same names):

   ```shell
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f praefect_production.sql postgres
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f gitlabhq_production.sql postgres
   ```

1. Optional. If you migrate from a database that doesn't use PgBouncer to a database that does, you must manually add a [`pg_shadow_lookup` function](../gitaly/praefect.md#manual-database-setup) to the application database (usually `gitlabhq_production`).
1. Configure the GitLab application servers with the appropriate connection details
   for your destination PostgreSQL instance in your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['db_host'] = '<destination postgresql host>'
   ```

   For more information on GitLab multi-node setups, refer to the [reference architectures](../reference_architectures/_index.md).

1. Reconfigure for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Restart GitLab:

   ```shell
   sudo gitlab-ctl start
   ```
