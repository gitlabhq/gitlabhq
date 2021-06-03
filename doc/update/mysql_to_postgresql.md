---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrating from MySQL to PostgreSQL **(FREE SELF)**

This guide documents how to take a working GitLab instance that uses MySQL and
migrate it to a PostgreSQL database.

## Requirements

NOTE:
Support for MySQL was removed in GitLab 12.1. This procedure should be performed
**before** installing GitLab 12.1.

[pgLoader](https://pgloader.io/) 3.4.1+ is required, confirm with `pgloader -V`.

You can install it directly from your distribution, for example in
Debian/Ubuntu:

1. Search for the version:

   ```shell
   apt-cache madison pgloader
   ```

1. If the version is 3.4.1+, install it with:

   ```shell
   sudo apt-get install pgloader
   ```

   If your distribution's version is too old, use PostgreSQL's repository:

   ```shell
   # Add repository
   sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

   # Add key
   sudo apt-get install wget ca-certificates
   wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

   # Install package
   sudo apt-get update
   sudo apt-get install pgloader
   ```

For other distributions, follow the instructions in PostgreSQL's
[download page](https://www.postgresql.org/download/) to add their repository
and then install `pgloader`.

If you are migrating to a Docker based installation, you must install
pgLoader within the container as it is not included in the container image.

1. Start a shell session in the context of the running container:

   ```shell
   docker exec -it gitlab bash
   ```

1. Install pgLoader:

   ```shell
   apt-get update
   apt-get -y install pgloader
   ```

## Omnibus GitLab installations

For [Omnibus GitLab packages](https://about.gitlab.com/install/), you first
need to enable the bundled PostgreSQL:

1. Stop GitLab:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Edit `/etc/gitlab/gitlab.rb` to enable bundled PostgreSQL:

   ```ruby
   postgresql['enable'] = true
   ```

1. Edit `/etc/gitlab/gitlab.rb` to use the bundled PostgreSQL. Review all of the
   settings beginning with `db_` (such as `gitlab_rails['db_adapter']`). To use
   the default values, you can comment all of them out.

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

1. Start Puma and PostgreSQL so that we can prepare the schema:

   ```shell
   sudo gitlab-ctl start puma
   sudo gitlab-ctl start postgresql
   ```

1. Run the following commands to prepare the schema:

   ```shell
   sudo gitlab-rake db:create db:migrate
   ```

1. Stop Puma to prevent other database access from interfering with the loading of data:

   ```shell
   sudo gitlab-ctl stop puma
   ```

After these steps, you have a fresh PostgreSQL database with up-to-date schema.

Next, use `pgloader` to migrate the data from the old MySQL database to the
new PostgreSQL one:

1. Save the following snippet in a `commands.load` file, and edit with your
   MySQL database `username`, `password` and `host`:

   ```sql
   LOAD DATABASE
        FROM mysql://username:password@host/gitlabhq_production
        INTO postgresql://gitlab-psql@unix://var/opt/gitlab/postgresql:/gitlabhq_production

   WITH include no drop, truncate, disable triggers, create no tables,
        create no indexes, preserve index names, no foreign keys,
        data only

   SET MySQL PARAMETERS
   net_read_timeout = '90',
   net_write_timeout = '180'

   ALTER SCHEMA 'gitlabhq_production' RENAME TO 'public'

   ;
   ```

1. Start the migration:

   ```shell
   sudo -u gitlab-psql pgloader commands.load
   ```

1. After the migration finishes, you should see a summary table that looks like
   the following:

   ```plaintext
                                    table name       read   imported     errors      total time
   -----------------------------------------------  ---------  ---------  ---------  --------------
                                   fetch meta data        119        119          0          0.388s
                                          Truncate        119        119          0          1.134s
   -----------------------------------------------  ---------  ---------  ---------  --------------
                              public.abuse_reports          0          0          0          0.490s
                                public.appearances          0          0          0          0.488s
                                          .
                                          .
                                          .
                              public.web_hook_logs          0          0          0          1.080s
   -----------------------------------------------  ---------  ---------  ---------  --------------
                           COPY Threads Completion          4          4          0          2.008s
                                   Reset Sequences        113        113          0          0.304s
                                  Install Comments          0          0          0          0.000s
   -----------------------------------------------  ---------  ---------  ---------  --------------
                                 Total import time       1894       1894          0         12.497s
   ```

   If there is no output for more than 30 minutes, it's possible `pgloader` encountered an error. See
   the [troubleshooting guide](#troubleshooting) for more details.

1. Start GitLab:

   ```shell
   sudo gitlab-ctl start
   ```

You can now verify that everything works as expected by visiting GitLab.

## Source installations

For installations from source that use MySQL, you must first
[install PostgreSQL and create a database](../install/installation.md#6-database).

After the database is created, go on with the following steps:

1. Stop GitLab:

   ```shell
   sudo service gitlab stop
   ```

1. Switch database from MySQL to PostgreSQL

   ```shell
   cd /home/git/gitlab
   sudo -u git mv config/database.yml config/database.yml.bak
   sudo -u git cp config/database.yml.postgresql config/database.yml
   sudo -u git -H chmod o-rwx config/database.yml
   ```

1. Install Gems related to PostgreSQL

   ```shell
   sudo -u git -H rm .bundle/config
   sudo -u git -H bundle install --deployment --without development test mysql aws kerberos
   ```

1. Run the following commands to prepare the schema:

   ```shell
   sudo -u git -H bundle exec rake db:create db:migrate RAILS_ENV=production
   ```

After these steps, you have a fresh PostgreSQL database with up-to-date schema.

Next, use `pgloader` to migrate the data from the old MySQL database to the
new PostgreSQL one:

1. Save the following snippet in a `commands.load` file, and edit with your
   MySQL `username`, `password` and `host`:

   ```sql
   LOAD DATABASE
        FROM mysql://username:password@host/gitlabhq_production
        INTO postgresql://postgres@unix://var/run/postgresql:/gitlabhq_production

   WITH include no drop, truncate, disable triggers, create no tables,
        create no indexes, preserve index names, no foreign keys,
        data only

   SET MySQL PARAMETERS
   net_read_timeout = '90',
   net_write_timeout = '180'

   ALTER SCHEMA 'gitlabhq_production' RENAME TO 'public'

   ;
   ```

1. Start the migration:

   ```shell
   sudo -u postgres pgloader commands.load
   ```

1. After the migration finishes, you should see a summary table that looks like
   the following:

   ```plaintext
                                    table name       read   imported     errors      total time
   -----------------------------------------------  ---------  ---------  ---------  --------------
                                   fetch meta data        119        119          0          0.388s
                                          Truncate        119        119          0          1.134s
   -----------------------------------------------  ---------  ---------  ---------  --------------
                              public.abuse_reports          0          0          0          0.490s
                                public.appearances          0          0          0          0.488s
                                          .
                                          .
                                          .
                              public.web_hook_logs          0          0          0          1.080s
   -----------------------------------------------  ---------  ---------  ---------  --------------
                           COPY Threads Completion          4          4          0          2.008s
                                   Reset Sequences        113        113          0          0.304s
                                  Install Comments          0          0          0          0.000s
   -----------------------------------------------  ---------  ---------  ---------  --------------
                                 Total import time       1894       1894          0         12.497s
   ```

   If there is no output for more than 30 minutes, it's possible `pgloader` encountered an error. See
   the [troubleshooting guide](#troubleshooting) for more details.

1. Start GitLab:

   ```shell
   sudo service gitlab start
   ```

You can now verify that everything works as expected by visiting GitLab.

## Troubleshooting

Sometimes, you might encounter some errors during or after the migration.

### Database error permission denied

The PostgreSQL user that you use for the migration MUST have **superuser** privileges.
Otherwise, you may see a similar message to the following:

```plaintext
debugger invoked on a CL-POSTGRES-ERROR:INSUFFICIENT-PRIVILEGE in thread
    #<THREAD "lparallel" RUNNING {10078A3513}>:
      Database error 42501: permission denied: "RI_ConstraintTrigger_a_20937" is a system trigger
    QUERY: ALTER TABLE ci_builds DISABLE TRIGGER ALL;
    2017-08-23T00:36:56.782000Z ERROR Database error 42501: permission denied: "RI_ConstraintTrigger_c_20864" is a system trigger
    QUERY: ALTER TABLE approver_groups DISABLE TRIGGER ALL;
```

### Experiencing 500 errors after the migration

If you experience 500 errors after the migration, try to clear the cache:

```shell
# Omnibus GitLab
sudo gitlab-rake cache:clear

# Installations from source
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```
