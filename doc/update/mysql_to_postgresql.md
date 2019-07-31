---
last_updated: 2019-06-18
---

# Migrating from MySQL to PostgreSQL

This guide documents how to take a working GitLab instance that uses MySQL and
migrate it to a PostgreSQL database.

## Requirements

NOTE: **Note:**
Support for MySQL was removed in GitLab 12.1. This procedure should be performed
**before** installing GitLab 12.1.

[pgloader](https://pgloader.io/) 3.4.1+ is required.

You can install it directly from your distribution, for example in
Debian/Ubuntu:

1. Search for the version:

   ```bash
   apt-cache madison pgloader
   ```

1. If the version is 3.4.1+, install it with:

   ```bash
   sudo apt-get install pgloader
   ```

   If your distribution's version is too old, use PostgreSQL's repository:

   ```bash
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

If you are migrating to a Docker based installation, you will need to install
pgloader within the container as it is not included in the container image.

1. Start a shell session in the context of the running container:

   ``` bash
   docker exec -it gitlab bash
   ```

1. Install pgloader:

   ``` bash
   apt-get update
   apt-get -y install pgloader
   ```

## Omnibus GitLab installations

For [Omnibus GitLab packages](https://about.gitlab.com/install/), you'll first
need to enable the bundled PostgreSQL:

1. Stop GitLab:

   ```bash
   sudo gitlab-ctl stop
   ```

1. Edit `/etc/gitlab/gitlab.rb` to enable bundled PostgreSQL:

   ```
   postgresql['enable'] = true
   ```

1. Edit `/etc/gitlab/gitlab.rb` to use the bundled PostgreSQL. Please check
   all the settings beginning with `db_`, such as `gitlab_rails['db_adapter']`
   and alike. You could just comment all of them out so that we'll just use
   the defaults.

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.
1. Start Unicorn and PostgreSQL so that we can prepare the schema:

   ```bash
   sudo gitlab-ctl start unicorn
   sudo gitlab-ctl start postgresql
   ```

1. Run the following commands to prepare the schema:

   ```bash
   sudo gitlab-rake db:create db:migrate
   ```

1. Stop Unicorn to prevent other database access from interfering with the loading of data:

   ```bash
   sudo gitlab-ctl stop unicorn
   ```

After these steps, you'll have a fresh PostgreSQL database with up-to-date schema.

Next, we'll use `pgloader` to migrate the data from the old MySQL database to the
new PostgreSQL one:

1. Save the following snippet in a `commands.load` file, and edit with your
   MySQL database `username`, `password` and `host`:

   ```
   LOAD DATABASE
        FROM mysql://username:password@host/gitlabhq_production
        INTO postgresql://gitlab-psql@unix://var/opt/gitlab/postgresql:/gitlabhq_production

   WITH include no drop, truncate, disable triggers, create no tables,
        create no indexes, preserve index names, no foreign keys,
        data only

   ALTER SCHEMA 'gitlabhq_production' RENAME TO 'public'

   ;
   ```

1. Start the migration:

   ```bash
   sudo -u gitlab-psql pgloader commands.load
   ```

1. Once the migration finishes, you should see a summary table that looks like
   the following:

   ```
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

   ```bash
   sudo gitlab-ctl start
   ```

You can now verify that everything works as expected by visiting GitLab.

## Source installations

For installations from source that use MySQL, you'll first need to
[install PostgreSQL and create a database](../install/installation.md#6-database).

After the database is created, go on with the following steps:

1. Stop GitLab:

   ```bash
   sudo service gitlab stop
   ```

1. Switch database from MySQL to PostgreSQL

   ```bash
   cd /home/git/gitlab
   sudo -u git mv config/database.yml config/database.yml.bak
   sudo -u git cp config/database.yml.postgresql config/database.yml
   sudo -u git -H chmod o-rwx config/database.yml
   ```

1. Install Gems related to Postgresql

   ```bash
   sudo -u git -H rm .bundle/config
   sudo -u git -H bundle install --deployment --without development test mysql aws kerberos
   ```

1. Run the following commands to prepare the schema:

   ```bash
   sudo -u git -H bundle exec rake db:create db:migrate RAILS_ENV=production
   ```

After these steps, you'll have a fresh PostgreSQL database with up-to-date schema.

Next, we'll use `pgloader` to migrate the data from the old MySQL database to the
new PostgreSQL one:

1. Save the following snippet in a `commands.load` file, and edit with your
   MySQL `username`, `password` and `host`:

   ```
   LOAD DATABASE
        FROM mysql://username:password@host/gitlabhq_production
        INTO postgresql://postgres@unix://var/run/postgresql:/gitlabhq_production

   WITH include no drop, truncate, disable triggers, create no tables,
        create no indexes, preserve index names, no foreign keys,
        data only

   ALTER SCHEMA 'gitlabhq_production' RENAME TO 'public'

   ;
   ```

1. Start the migration:

   ```bash
   sudo -u postgres pgloader commands.load
   ```

1. Once the migration finishes, you should see a summary table that looks like
   the following:

   ```
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

   ```bash
   sudo service gitlab start
   ```

You can now verify that everything works as expected by visiting GitLab.

## Troubleshooting

Sometimes, you might encounter some errors during or after the migration.

### Database error permission denied

The PostgreSQL user that you use for the migration MUST have **superuser** privileges.
Otherwise, you may see a similar message to the following:

```
debugger invoked on a CL-POSTGRES-ERROR:INSUFFICIENT-PRIVILEGE in thread
    #<THREAD "lparallel" RUNNING {10078A3513}>:
      Database error 42501: permission denied: "RI_ConstraintTrigger_a_20937" is a system trigger
    QUERY: ALTER TABLE ci_builds DISABLE TRIGGER ALL;
    2017-08-23T00:36:56.782000Z ERROR Database error 42501: permission denied: "RI_ConstraintTrigger_c_20864" is a system trigger
    QUERY: ALTER TABLE approver_groups DISABLE TRIGGER ALL;
```

### Experiencing 500 errors after the migration

If you experience 500 errors after the migration, try to clear the cache:

```bash
# Omnibus GitLab
sudo gitlab-rake cache:clear

# Installations from source
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```
