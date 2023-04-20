---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Multiple Databases **(FREE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6168) in GitLab 15.7.

WARNING:
This feature is not ready for production use

By default, GitLab uses a single application database, referred to as the `main` database.

To scale GitLab, you can configure GitLab to use multiple application databases.

Due to [known issues](#known-issues), configuring GitLab with multiple databases is an [Experiment](../../policy/alpha-beta-support.md#experiment).

After you have set up multiple databases, GitLab uses a second application database for
[CI/CD features](../../ci/index.md), referred to as the `ci` database.

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

## Migrate existing installations

To migrate existing data from the `main` database to the `ci` database, you can
copy the database across.

### Existing source installation

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

### Existing Omnibus installation

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

## Set up multiple databases

To configure GitLab to use multiple application databases, follow the instructions below for your installation type.

WARNING:
You must stop GitLab before setting up multiple databases. This prevents
split-brain situations, where `main` data is written to the `ci` database, and
the other way around.

### Installations from source

1. For existing installations,
   [migrate the data](#migrate-existing-installations) first.

1. [Back up GitLab](../../raketasks/backup_restore.md)
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

### Omnibus GitLab installations

1. For existing installations,
   [migrate the data](#migrate-existing-installations) first.

1. [Back up GitLab](../../raketasks/backup_restore.md)
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

## Further information

For more information on multiple databases, see [issue 6168](https://gitlab.com/groups/gitlab-org/-/epics/6168).

For more information on how multiple databases work in GitLab, see the [development guide for multiple databases](../../development/database/multiple_databases.md).

Since 2022-07-02, GitLab.com has been running with two separate databases. For more information, see this [blog post](https://about.gitlab.com/blog/2022/06/02/splitting-database-into-main-and-ci/).
