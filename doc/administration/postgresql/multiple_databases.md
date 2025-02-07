---

stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Multiple Databases
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6168) in GitLab 15.7.

WARNING:
This feature is not ready for production use

By default, GitLab uses a single application database, referred to as the `main` database.

To scale GitLab, you can configure GitLab to use multiple application databases.

Due to [known issues](#known-issues), configuring GitLab with multiple databases is in limited [beta](../../policy/development_stages_support.md#beta).

After you have set up multiple databases, GitLab uses a second application database for
[CI/CD features](../../ci/_index.md), referred to as the `ci` database. We do not exclude hosting both databases on a single PostgreSQL instance.

All tables have exactly the same structure in both the `main`, and `ci`
databases. Some examples:

- When multiple databases are configured, the `ci_pipelines` table exists in
  both the `main` and `ci` databases, but GitLab reads and writes only to the
  `ci_pipelines` table in the `ci` database.
- Similarly, the `projects` table exists in
  both the `main` and `ci` databases, but GitLab reads and writes only to the
  `projects` table in the `main` database.
- For some tables (such as `loose_foreign_keys_deleted_records`) GitLab reads and writes to both the `main` and `ci` databases. See the
  [development documentation](../../development/database/multiple_databases.md#gitlab-schema)

## Known issues

- Once data is migrated to the `ci` database, you cannot migrate it back.
- Significant downtime is expected for larger installations (database sizes of more 100 GB).
- Running two databases [is not yet supported with Geo](https://gitlab.com/groups/gitlab-org/-/epics/8631).

## Migrate existing installations using a script

> - A script for migrating existing Linux package installations was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368729) in GitLab 16.8.

### Existing Linux package installations

This migration requires downtime.
If something unexpected happens during the migration, it is safe to start over.

#### Preparation

1. Verify available disk space:

   - The database node that will store the `gitlabhq_production_ci` database needs enough space to store a copy of the existing database: we _duplicate_ `gitlabhq_production`. Run the following SQL query to find out how much space is needed. Add 25%, to ensure you will not run out of disk space.

     ```shell
     sudo gitlab-psql -c "SELECT pg_size_pretty( pg_database_size('gitlabhq_production') );"
     ```

   - During the process, a dump of the `gitlabhq_production` database needs to be temporarily stored on the filesystem of the node that will run the migration. Execute the following SQL statement to find out how much local disk space will be used. Add 25%, to ensure you will not run out of disk space.

     ```shell
     sudo gitlab-psql -c "select sum(pg_table_size(concat(table_schema,'.',table_name))) from information_schema.tables where table_catalog = 'gitlabhq_production' and table_type = 'BASE TABLE'"
     ```

1. Plan for downtime. The downtime is dependent on the size of the `gitlabhq_production` database.

   - We dump `gitlabhq_production` and restore it into a new `gitlabhq_production_ci` database. Database sizes below 50 GB should be done within 30 minutes. Larger databases need more time. For example, a 100 GB database needs 1-2 hours to be copied to the new database.
   - We advise to also plan some time for smaller tasks like modifying the configuration.

1. Create the new `gitlabhq_production_ci` database:

   ```shell
   sudo gitlab-psql -c "CREATE DATABASE gitlabhq_production_ci WITH OWNER 'gitlab'"
   ```

#### Migration

This process includes downtime. Running the migration script will stop the GitLab instance. After the migration has been finished, the instance is restarted.

1. Create a backup of the configuration:

   ```shell
   sudo cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.org
   ```

1. Edit `/etc/gitlab/gitlab.rb` and save the changes. Do **not** run the reconfigure command, the migration script will run that for you.

   ```ruby
   gitlab_rails['env'] = { 'GITLAB_ALLOW_SEPARATE_CI_DATABASE' => 'true' }
   gitlab_rails['databases']['ci']['enable'] = true
   gitlab_rails['databases']['ci']['db_database'] = 'gitlabhq_production_ci'
   ```

1. Run the migration script:

   ```shell
   sudo gitlab-ctl pg-decomposition-migration
   ```

At this point, the GitLab instance should start and be functional.

If you want to abort the procedure and you want to start GitLab without changing anything, run the following commands:

```shell
sudo cp /etc/gitlab/gitlab.rb.org /etc/gitlab/gitlab.rb
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

#### Cleaning up

If everything works as expected, we can clean up unneeded data:

- Delete the CI data in Main database:

```shell
sudo gitlab-rake gitlab:db:truncate_legacy_tables:main
```

- Delete the Main data in CI database:

```shell
sudo gitlab-rake gitlab:db:truncate_legacy_tables:ci
```

## Migrate existing installations (manual procedure)

To migrate existing data from the `main` database to the `ci` database, you can
copy the database across.

NOTE:
If something unexpected happens during the migration, it is safe to start over.

### Existing self-compiled installation

1. [Disable background migrations](../../development/database/batched_background_migrations.md#enable-or-disable-background-migrations).

1. [Ensure all background migrations are finished](../../update/background_migrations.md#check-the-status-of-batched-background-migrations).

1. Stop GitLab, except for PostgreSQL:

   ```shell
   sudo service gitlab stop
   sudo service postgresql start
   ```

1. Dump the `main` database:

   ```shell
   sudo -u git pg_dump -f gitlabhq_production.sql gitlabhq_production
   ```

1. Create the `ci` database, and copy the data from the previous dump:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production_ci OWNER git;"
   sudo -u git psql -f gitlabhq_production.sql gitlabhq_production_ci
   ```

1. Configure GitLab to [use multiple databases](#set-up-multiple-databases).

### Existing Linux package installations

1. [Disable background migrations](../../development/database/batched_background_migrations.md#enable-or-disable-background-migrations)

1. [Ensure all background migrations are finished](../../update/background_migrations.md#check-the-status-of-batched-background-migrations)

1. Stop GitLab, except for PostgreSQL:

   ```shell
   sudo gitlab-ctl stop
   sudo gitlab-ctl start postgresql
   ```

1. Dump the `main` database:

   ```shell
   sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_dump -h /var/opt/gitlab/postgresql -f gitlabhq_production.sql gitlabhq_production
   ```

1. Create the `ci` database, and copy the data from the previous dump:

   ```shell
   sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d template1 -c "CREATE DATABASE gitlabhq_production_ci OWNER gitlab;"
   sudo -u gitlab-psql  /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -f gitlabhq_production.sql gitlabhq_production_ci
   ```

1. Configure GitLab to [use multiple databases](#set-up-multiple-databases).

### Existing Linux package installations using streaming replication

To reduce downtime, you can set up streaming replication to migrate existing data from the `main` database to the `ci` database.
This procedure results in two database clusters.

This procedure can be both time- and resource-consuming.
Consider their trade-offs with availability before executing it.

To set up streaming replication for creating two database clusters:

1. Set up streaming replication from the GitLab database to new database instance.
1. When the new replica has caught up, [disable background migrations](../../development/database/batched_background_migrations.md#enable-or-disable-background-migrations).
1. [Ensure all background migrations are finished](../../update/background_migrations.md#check-the-status-of-batched-background-migrations).
1. Stop GitLab, except for PostgreSQL:

   ```shell
   sudo gitlab-ctl stop
   sudo gitlab-ctl start postgresql
   ```

1. After the replication is complete, stop the streaming replication, and promote the replica to a primary instance.
   You now have two database clusters, one for `main`, and one for `ci`.
1. Configure GitLab to [use multiple databases](#set-up-multiple-databases).

For more information on how to set up Streaming Replication,
see [PostgreSQL replication and failover for Linux package installations](replication_and_failover.md).

## Set up multiple databases

To configure GitLab to use multiple application databases, follow the instructions below for your installation type.

WARNING:
You must stop GitLab before setting up multiple databases. This prevents
split-brain situations, where `main` data is written to the `ci` database, and
the other way around.

### Self-compiled installations

1. For existing installations,
   [migrate the data](#migrate-existing-installations-manual-procedure) first.

1. [Back up GitLab](../backup_restore/_index.md)
   in case of unforeseen issues.

1. Stop GitLab:

   ```shell
   sudo service gitlab stop
   ```

1. Open `config/database.yml`, and add a `ci:` section under
   `production:`. See `config/database.yml.decomposed-postgresql` for possible
   values for this new `ci:` section. Once modified, the `config/database.yml` should
   look like:

   ```yaml
   production:
     main:
       # ...
     ci:
       adapter: postgresql
       encoding: unicode
       database: gitlabhq_production_ci
       # ...
   ```

1. Save the `config/database.yml` file.

1. Update the service files to set the `GITLAB_ALLOW_SEPARATE_CI_DATABASE`
   environment variable to `true`.

1. For new installations only. Create the `gitlabhq_production_ci` database:

   ```shell
   sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
   sudo -u git -H bundle exec rake db:schema:load:ci
   ```

1. Lock writes for `ci` tables in `main` database, and the other way around:

   ```shell
   sudo -u git -H bundle exec rake gitlab:db:lock_writes
   ```

1. Restart GitLab:

   ```shell
   sudo service gitlab restart
   ```

1. [Enable background migrations](../../development/database/batched_background_migrations.md#enable-or-disable-background-migrations)

### Linux package installations

1. For existing installations,
   [migrate the data](#migrate-existing-installations-manual-procedure) first.

1. [Back up GitLab](../backup_restore/_index.md)
   in case of unforeseen issues.

1. Stop GitLab:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines:

   ```ruby
   gitlab_rails['env'] = { 'GITLAB_ALLOW_SEPARATE_CI_DATABASE' => 'true' }
   gitlab_rails['databases']['ci']['enable'] = true
   gitlab_rails['databases']['ci']['db_database'] = 'gitlabhq_production_ci'
   ```

1. Save the `/etc/gitlab/gitlab.rb` file.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional, for new installations only. Reconfiguring GitLab should create the
   `gitlabhq_production_ci` database if it does not exist. If the database is not created automatically, create it manually:

   ```shell
   sudo gitlab-ctl start postgresql
   sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -h /var/opt/gitlab/postgresql -d template1 -c "CREATE DATABASE gitlabhq_production_ci OWNER gitlab;"
   sudo gitlab-rake db:schema:load:ci
   ```

1. Lock writes for `ci` tables in `main` database, and the other way around:

   ```shell
   sudo gitlab-ctl start postgresql
   sudo gitlab-rake gitlab:db:lock_writes
   ```

1. Restart GitLab:

   ```shell
   sudo gitlab-ctl restart
   ```

1. [Enable background migrations](../../development/database/batched_background_migrations.md#enable-or-disable-background-migrations)

## Further information

For more information on multiple databases, see [issue 6168](https://gitlab.com/groups/gitlab-org/-/epics/6168).

For more information on how multiple databases work in GitLab, see the [development guide for multiple databases](../../development/database/multiple_databases.md).

Since 2022-07-02, GitLab.com has been running with two separate databases. For more information, see this [blog post](https://about.gitlab.com/blog/2022/06/02/splitting-database-into-main-and-ci/).
