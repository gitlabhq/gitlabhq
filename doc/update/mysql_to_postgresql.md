---
last_updated: 2017-10-05
---

# Migrating from MySQL to PostgreSQL

> **Note:** This guide assumes you have a working Omnibus GitLab instance with
> MySQL and want to migrate to bundled PostgreSQL database.

## Prerequisites

First, we'll need to enable the bundled PostgreSQL database with up-to-date
schema. Next, we'll use [pgloader](http://pgloader.io) to migrate the data
from the old MySQL database to the new PostgreSQL one.

Here's what you'll need to have installed:

- pgloader 3.4.1+
- Omnibus GitLab
- MySQL

## Enable bundled PostgreSQL database

1. Stop GitLab:

    ``` bash
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

1. [Reconfigure GitLab] for the changes to take effect:

    ``` bash
    sudo gitlab-ctl reconfigure
    ```

1. Start Unicorn and PostgreSQL so that we could prepare the schema:

    ``` bash
    sudo gitlab-ctl start unicorn
    sudo gitlab-ctl start posgresql
    ```

1. Run the following commands to prepare the schema:

    ``` bash
    sudo gitlab-rake db:create db:migrate
    ```

1. Stop Unicorn in case it's interfering the next step:

    ``` bash
    sudo gitlab-ctl stop unicorn
    ```

After these steps, you'll have a fresh PostgreSQL database with up-to-date schema.

## Migrate data from MySQL to PostgreSQL

Now, you can use pgloader to migrate the data from MySQL to PostgreSQL:

1. Save the following snippet in a `commands.load` file, and edit with your
   database `username`, `password` and `host`:

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

    ``` bash
    sudo -u gitlab-psql pgloader commands.load
    ```

1. Once the migration finishes, start GitLab:

    ``` bash
    sudo gitlab-ctl start
    ```

Now, you can verify that everything worked by visiting GitLab.

## Troubleshooting

### Experiencing 500 errors after the migration

If you experience 500 errors after the migration, try to clear the cache:

``` bash
sudo gitlab-rake cache:clear
```

[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
