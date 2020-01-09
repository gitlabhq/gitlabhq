# Geo Troubleshooting **(PREMIUM ONLY)**

Setting up Geo requires careful attention to details and sometimes it's easy to
miss a step.

Here is a list of steps you should take to attempt to fix problem:

- Perform [basic troubleshooting](#basic-troubleshooting).
- Fix any [replication errors](#fixing-replication-errors).
- Fix any [Foreign Data Wrapper](#fixing-foreign-data-wrapper-errors) errors.
- Fix any [common](#fixing-common-errors) errors.

## Basic troubleshooting

Before attempting more advanced troubleshooting:

- Check [the health of the **secondary** node](#check-the-health-of-the-secondary-node).
- Check [if PostgreSQL replication is working](#check-if-postgresql-replication-is-working).

### Check the health of the **secondary** node

Visit the **primary** node's **Admin Area > Geo** (`/admin/geo/nodes`) in
your browser. We perform the following health checks on each **secondary** node
to help identify if something is wrong:

- Is the node running?
- Is the node's secondary database configured for streaming replication?
- Is the node's secondary tracking database configured?
- Is the node's secondary tracking database connected?
- Is the node's secondary tracking database up-to-date?

![Geo health check](img/geo_node_healthcheck.png)

For information on how to resolve common errors reported from the UI, see
[Fixing Common Errors](#fixing-common-errors).

If the UI is not working, or you are unable to log in, you can run the Geo
health check manually to get this information as well as a few more details.

This rake task can be run on an app node in the **primary** or **secondary**
Geo nodes:

```sh
sudo gitlab-rake gitlab:geo:check
```

Example output:

```text
Checking Geo ...

GitLab Geo is available ... yes
GitLab Geo is enabled ... yes
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
GitLab Geo secondary database is correctly configured ... yes
Database replication enabled? ... yes
Database replication working? ... yes
GitLab Geo tracking database is configured to use Foreign Data Wrapper? ... yes
GitLab Geo tracking database Foreign Data Wrapper schema is up-to-date? ... yes
GitLab Geo HTTP(S) connectivity ...
* Can connect to the primary node ... yes
HTTP/HTTPS repository cloning is enabled ... yes
Machine clock is synchronized ... yes
Git user has default SSH configuration? ... yes
OpenSSH configured to use AuthorizedKeysCommand ... yes
GitLab configured to disable writing to authorized_keys file ... yes
GitLab configured to store new projects in hashed storage? ... yes
All projects are in hashed storage? ... yes

Checking Geo ... Finished
```

Current sync information can be found manually by running this rake task on any
**secondary** app node:

```sh
sudo gitlab-rake geo:status
```

Example output:

```text
http://secondary.example.com/
-----------------------------------------------------
                        GitLab Version: 11.10.4-ee
                              Geo Role: Secondary
                         Health Status: Healthy
                          Repositories: 289/289 (100%)
                 Verified Repositories: 289/289 (100%)
                                 Wikis: 289/289 (100%)
                        Verified Wikis: 289/289 (100%)
                           LFS Objects: 8/8 (100%)
                           Attachments: 5/5 (100%)
                      CI job artifacts: 0/0 (0%)
                  Repositories Checked: 0/289 (0%)
                         Sync Settings: Full
              Database replication lag: 0 seconds
       Last event ID seen from primary: 10215 (about 2 minutes ago)
     Last event ID processed by cursor: 10215 (about 2 minutes ago)
                Last status report was: 2 minutes ago
```

### Check if PostgreSQL replication is working

To check if PostgreSQL replication is working, check if:

- [Nodes are pointing to the correct database instance](#are-nodes-pointing-to-the-correct-database-instance).
- [Geo can detect the current node correctly](#can-geo-detect-the-current-node-correctly).

#### Are nodes pointing to the correct database instance?

You should make sure your **primary** Geo node points to the instance with
writing permissions.

Any **secondary** nodes should point only to read-only instances.

#### Can Geo detect the current node correctly?

Geo finds the current machine's Geo node name in `/etc/gitlab/gitlab.rb` by:

- Using the `gitlab_rails['geo_node_name']` setting.
- If that is not defined, using the `external_url` setting.

This name is used to look up the node with the same **Name** in
**Admin Area > Geo**.

To check if the current machine has a node name that matches a node in the
database, run the check task:

```sh
sudo gitlab-rake gitlab:geo:check
```

It displays the current machine's node name and whether the matching database
record is a **primary** or **secondary** node.

```
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
```

```
This machine's Geo node name matches a database record ... no
  Try fixing it:
  You could add or update a Geo node database record, setting the name to "https://example.com/".
  Or you could set this machine's Geo node name to match the name of an existing database record: "London", "Shanghai"
  For more information see:
  doc/administration/geo/replication/troubleshooting.md#can-geo-detect-the-current-node-correctly
```

## Fixing errors found when running the Geo check rake task

When running this rake task, you may see errors if the nodes are not properly configured:

```sh
sudo gitlab-rake gitlab:geo:check
```

1. Rails did not provide a password when connecting to the database

    ```text
    Checking Geo ...

    GitLab Geo is available ... Exception: fe_sendauth: no password supplied
    GitLab Geo is enabled ... Exception: fe_sendauth: no password supplied
    ...
    Checking Geo ... Finished
    ```

    - Ensure that you have the `gitlab_rails['db_password']` set to the plain text-password used when creating the hash for `postgresql['sql_user_password']`.

1. Rails is unable to connect to the database

    ```text
    Checking Geo ...

    GitLab Geo is available ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1",  user "gitlab", database "gitlabhq_production", SSL on
    FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
    GitLab Geo is enabled ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL on
    FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
    ...
    Checking Geo ... Finished
    ```

    - Ensure that you have the IP address of the rails node included in `postgresql['md5_auth_cidr_addresses']`.
    - Ensure that you have included the subnet mask on the IP address: `postgresql['md5_auth_cidr_addresses'] = ['1.1.1.1/32']`.

1. Rails has supplied the incorrect password

    ```text
    Checking Geo ...
    GitLab Geo is available ... Exception: FATAL:  password authentication failed for user "gitlab"
    FATAL:  password authentication failed for user "gitlab"
    GitLab Geo is enabled ... Exception: FATAL:  password authentication failed for user "gitlab"
    FATAL:  password authentication failed for user "gitlab"
    ...
    Checking Geo ... Finished
    ```

    - Verify the correct password is set for `gitlab_rails['db_password']` that was used when creating the hash in  `postgresql['sql_user_password']` by running `gitlab-ctl pg-password-md5 gitlab` and entering the password.

1. Check returns not a secondary node

    ```text
    Checking Geo ...

    GitLab Geo is available ... yes
    GitLab Geo is enabled ... yes
    GitLab Geo secondary database is correctly configured ... not a secondary node
    Database replication enabled? ... not a secondary node
    ...
    Checking Geo ... Finished
    ```

    - Ensure that you have added the secondary node in the Admin Area of the primary node.
    - Ensure that you entered the `external_url` or `gitlab_rails['geo_node_name']` when adding the secondary node in the admin are of the primary node.
    - Prior to GitLab 12.4, edit the secondary node in the Admin Area of the primary node and ensure that there is a trailing `/` in the `Name` field.

1. Check returns Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist

    ```text
    Checking Geo ...

    GitLab Geo is available ... no
      Try fixing it:
      Upload a new license that includes the GitLab Geo feature
      For more information see:
      https://about.gitlab.com/features/gitlab-geo/
    GitLab Geo is enabled ... Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist
    LINE 8:                WHERE a.attrelid = '"geo_nodes"'::regclass
                                              ^
    :               SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                         pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
                         c.collname, col_description(a.attrelid, a.attnum) AS comment
                    FROM pg_attribute a
                    LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
                    LEFT JOIN pg_type t ON a.atttypid = t.oid
                    LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
                   WHERE a.attrelid = '"geo_nodes"'::regclass
                     AND a.attnum > 0 AND NOT a.attisdropped
                   ORDER BY a.attnum
    ...
    Checking Geo ... Finished
    ```

    When performing a Postgres major version (9 > 10) update this is expected.  Follow:

    - [initiate-the-replication-process](https://docs.gitlab.com/ee/administration/geo/replication/database.html#step-3-initiate-the-replication-process)
    - [Geo database has an outdated FDW remote schema](https://docs.gitlab.com/ee/administration/geo/replication/troubleshooting.html#geo-database-has-an-outdated-fdw-remote-schema-error)

## Fixing replication errors

The following sections outline troubleshooting steps for fixing replication
errors.

### Message: "ERROR:  replication slots can only be used if max_replication_slots > 0"?

This means that the `max_replication_slots` PostgreSQL variable needs to
be set on the **primary** database. In GitLab 9.4, we have made this setting
default to 1. You may need to increase this value if you have more
**secondary** nodes.

Be sure to restart PostgreSQL for this to take
effect. See the [PostgreSQL replication
setup][database-pg-replication] guide for more details.

### Message: "FATAL:  could not start WAL streaming: ERROR:  replication slot "geo_secondary_my_domain_com" does not exist"?

This occurs when PostgreSQL does not have a replication slot for the
**secondary** node by that name.

You may want to rerun the [replication
process](database.md) on the **secondary** node .

### Message: "Command exceeded allowed execution time" when setting up replication?

This may happen while [initiating the replication process][database-start-replication] on the **secondary** node,
and indicates that your initial dataset is too large to be replicated in the default timeout (30 minutes).

Re-run `gitlab-ctl replicate-geo-database`, but include a larger value for
`--backup-timeout`:

```sh
sudo gitlab-ctl \
   replicate-geo-database \
   --host=<primary_node_hostname> \
   --slot-name=<secondary_slot_name> \
   --backup-timeout=21600
```

This will give the initial replication up to six hours to complete, rather than
the default thirty minutes. Adjust as required for your installation.

### Message: "PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device"

Determine if you have any unused replication slots in the **primary** database. This can cause large amounts of
log data to build up in `pg_xlog`. Removing the unused slots can reduce the amount of space used in the `pg_xlog`.

1. Start a PostgreSQL console session:

   ```sh
   sudo gitlab-psql gitlabhq_production
   ```

   Note: **Note:** Using `gitlab-rails dbconsole` will not work, because managing replication slots requires superuser permissions.

1. View your replication slots with:

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

Slots where `active` is `f` are not active.

- When this slot should be active, because you have a **secondary** node configured using that slot,
  log in to that **secondary** node and check the PostgreSQL logs why the replication is not running.

- If you are no longer using the slot (e.g. you no longer have Geo enabled), you can remove it with in the
  PostgreSQL console session:

  ```sql
  SELECT pg_drop_replication_slot('<name_of_extra_slot>');
  ```

### Message: "ERROR: canceling statement due to conflict with recovery"

This error may rarely occur under normal usage, and the system is resilient
enough to recover.

However, under certain conditions, some database queries on secondaries may run
excessively long, which increases the frequency of this error. At some point,
some of these queries will never be able to complete due to being canceled
every time.

These long-running queries are
[planned to be removed in the future](https://gitlab.com/gitlab-org/gitlab/issues/34269),
but as a workaround, we recommend enabling
[hot_standby_feedback](https://www.postgresql.org/docs/10/hot-standby.html#HOT-STANDBY-CONFLICT).
This increases the likelihood of bloat on the **primary** node as it prevents
`VACUUM` from removing recently-dead rows. However, it has been used
successfully in production on GitLab.com.

To enable `hot_standby_feedback`, add the following to `/etc/gitlab/gitlab.rb`
on the **secondary** node:

```ruby
postgresql['hot_standby_feedback'] = 'on'
```

Then reconfigure GitLab:

```sh
sudo gitlab-ctl reconfigure
```

To help us resolve this problem, consider commenting on
[the issue](https://gitlab.com/gitlab-org/gitlab/issues/4489).

### Very large repositories never successfully synchronize on the **secondary** node

GitLab places a timeout on all repository clones, including project imports
and Geo synchronization operations. If a fresh `git clone` of a repository
on the primary takes more than a few minutes, you may be affected by this.

To increase the timeout, add the following line to `/etc/gitlab/gitlab.rb`
on the **secondary** node:

```ruby
gitlab_rails['gitlab_shell_git_timeout'] = 10800
```

Then reconfigure GitLab:

```sh
sudo gitlab-ctl reconfigure
```

This will increase the timeout to three hours (10800 seconds). Choose a time
long enough to accommodate a full clone of your largest repositories.

### Resetting Geo **secondary** node replication

If you get a **secondary** node in a broken state and want to reset the replication state,
to start again from scratch, there are a few steps that can help you:

1. Stop Sidekiq and the Geo LogCursor

   It's possible to make Sidekiq stop gracefully, but making it stop getting new jobs and
   wait until the current jobs to finish processing.

   You need to send a **SIGTSTP** kill signal for the first phase and them a **SIGTERM**
   when all jobs have finished. Otherwise just use the `gitlab-ctl stop` commands.

   ```sh
   gitlab-ctl status sidekiq
   # run: sidekiq: (pid 10180) <- this is the PID you will use
   kill -TSTP 10180 # change to the correct PID

   gitlab-ctl stop sidekiq
   gitlab-ctl stop geo-logcursor
   ```

   You can watch Sidekiq logs to know when Sidekiq jobs processing have finished:

   ```sh
   gitlab-ctl tail sidekiq
   ```

1. Rename repository storage folders and create new ones. If you are not concerned about possible orphaned directories and files, then you can simply skip this step.

   ```sh
   mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
   mkdir -p /var/opt/gitlab/git-data/repositories
   chown git:git /var/opt/gitlab/git-data/repositories
   ```

   TIP: **Tip**
   You may want to remove the `/var/opt/gitlab/git-data/repositories.old` in the future
   as soon as you confirmed that you don't need it anymore, to save disk space.

1. _(Optional)_ Rename other data folders and create new ones

   CAUTION: **Caution**:
   You may still have files on the **secondary** node that have been removed from **primary** node but
   removal have not been reflected. If you skip this step, they will never be removed
   from this Geo node.

   Any uploaded content like file attachments, avatars or LFS objects are stored in a
   subfolder in one of the two paths below:

   - `/var/opt/gitlab/gitlab-rails/shared`
   - `/var/opt/gitlab/gitlab-rails/uploads`

   To rename all of them:

   ```sh
   gitlab-ctl stop

   mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
   mkdir -p /var/opt/gitlab/gitlab-rails/shared

   mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
   mkdir -p /var/opt/gitlab/gitlab-rails/uploads

   gitlab-ctl start geo-postgresql
   ```

   Reconfigure in order to recreate the folders and make sure permissions and ownership
   are correctly

   ```sh
   gitlab-ctl reconfigure
   ```

1. Reset the Tracking Database

   ```sh
   gitlab-rake geo:db:drop
   gitlab-ctl reconfigure
   gitlab-rake geo:db:setup
   ```

1. Restart previously stopped services

   ```sh
   gitlab-ctl start
   ```

## Fixing Foreign Data Wrapper errors

This section documents ways to fix potential Foreign Data Wrapper errors.

### "Foreign Data Wrapper (FDW) is not configured" error

When setting up Geo, you might see this warning in the `gitlab-rake
gitlab:geo:check` output:

```text
GitLab Geo tracking database Foreign Data Wrapper schema is up-to-date? ... foreign data wrapper is not configured
```

There are a few key points to remember:

1. The FDW settings are configured on the Geo **tracking** database.
1. The configured foreign server enables a login to the Geo
   **secondary**, read-only database.

By default, the Geo secondary and tracking database are running on the
same host on different ports. That is, 5432 and 5431 respectively.

#### Checking configuration

NOTE: **Note:**
The following steps are for Omnibus installs only. Using Geo with source-based installs was **deprecated** in GitLab 11.5.

To check the configuration:

1. Enter the database console:

   ```sh
   gitlab-geo-psql
   ```

1. Check whether any tables are present. If everything is working, you
   should see something like this:

   ```sql
   gitlabhq_geo_production=# SELECT * from information_schema.foreign_tables;
     foreign_table_catalog  | foreign_table_schema |               foreign_table_name                | foreign_server_catalog  | foreign_server_name
   -------------------------+----------------------+-------------------------------------------------+-------------------------+---------------------
    gitlabhq_geo_production | gitlab_secondary     | abuse_reports                                   | gitlabhq_geo_production | gitlab_secondary
    gitlabhq_geo_production | gitlab_secondary     | appearances                                     | gitlabhq_geo_production | gitlab_secondary
    gitlabhq_geo_production | gitlab_secondary     | application_setting_terms                       | gitlabhq_geo_production | gitlab_secondary
    gitlabhq_geo_production | gitlab_secondary     | application_settings                            | gitlabhq_geo_production | gitlab_secondary
   <snip>
   ```

   However, if the query returns with `0 rows`, then continue onto the next steps.

1. Check that the foreign server mapping is correct via `\des+`. The
   results should look something like this:

   ```sql
   gitlabhq_geo_production=# \des+
   List of foreign servers
   -[ RECORD 1 ]--------+------------------------------------------------------------
   Name                 | gitlab_secondary
   Owner                | gitlab-psql
   Foreign-data wrapper | postgres_fdw
   Access privileges    | "gitlab-psql"=U/"gitlab-psql"                              +
                        | gitlab_geo=U/"gitlab-psql"
   Type                 |
   Version              |
   FDW Options          | (host '0.0.0.0', port '5432', dbname 'gitlabhq_production')
   Description          |
   ```

   NOTE: **Note:** Pay particular attention to the host and port under
   FDW options. That configuration should point to the Geo secondary
   database.

   If you need to experiment with changing the host or password, the
   following queries demonstrate how:

   ```sql
   ALTER SERVER gitlab_secondary OPTIONS (SET host '<my_new_host>');
   ALTER SERVER gitlab_secondary OPTIONS (SET port 5432);
   ```

   If you change the host and/or port, you will also have to adjust the
   following settings in `/etc/gitlab/gitlab.rb` and run `gitlab-ctl
   reconfigure`:

   - `gitlab_rails['db_host']`
   - `gitlab_rails['db_port']`

1. Check that the user mapping is configured properly via `\deu+`:

   ```sql
   gitlabhq_geo_production=# \deu+
                                                List of user mappings
         Server      | User name  |                                  FDW Options
   ------------------+------------+--------------------------------------------------------------------------------
    gitlab_secondary | gitlab_geo | ("user" 'gitlab', password 'YOUR-PASSWORD-HERE')
   (1 row)
   ```

   Make sure the password is correct. You can test that logins work by running `psql`:

   ```sh
   # Connect to the tracking database as the `gitlab_geo` user
   sudo \
      -u git /opt/gitlab/embedded/bin/psql \
      -h /var/opt/gitlab/geo-postgresql \
      -p 5431 \
      -U gitlab_geo \
      -W \
      -d gitlabhq_geo_production
   ```

   If you need to correct the password, the following query shows how:

   ```sql
   ALTER USER MAPPING FOR gitlab_geo SERVER gitlab_secondary OPTIONS (SET password '<my_new_password>');
   ```

   If you change the user or password, you will also have to adjust the
   following settings in `/etc/gitlab/gitlab.rb` and run `gitlab-ctl
   reconfigure`:

   - `gitlab_rails['db_username']`
   - `gitlab_rails['db_password']`

   If you are using [PgBouncer in front of the secondary
   database](database.md#pgbouncer-support-optional), be sure to update
   the following settings:

   - `geo_postgresql['fdw_external_user']`
   - `geo_postgresql['fdw_external_password']`

#### Manual reload of FDW schema

If you're still unable to get FDW working, you may want to try a manual
reload of the FDW schema. To manually reload the FDW schema:

1. On the node running the Geo tracking database, enter the PostgreSQL console via
   the `gitlab_geo` user:

   ```sh
   sudo \
      -u git /opt/gitlab/embedded/bin/psql \
      -h /var/opt/gitlab/geo-postgresql \
      -p 5431 \
      -U gitlab_geo \
      -W \
      -d gitlabhq_geo_production
   ```

   Be sure to adjust the port and hostname for your configuration. You
   may be asked to enter a password.

1. Reload the schema via:

   ```sql
   DROP SCHEMA IF EXISTS gitlab_secondary CASCADE;
   CREATE SCHEMA gitlab_secondary;
   GRANT USAGE ON FOREIGN SERVER gitlab_secondary TO gitlab_geo;
   IMPORT FOREIGN SCHEMA public FROM SERVER gitlab_secondary INTO gitlab_secondary;
   ```

1. Test that queries work:

   ```sql
   SELECT * from information_schema.foreign_tables;
   SELECT * FROM gitlab_secondary.projects limit 1;
   ```

[database-start-replication]: database.md#step-3-initiate-the-replication-process
[database-pg-replication]: database.md#postgresql-replication

### "Geo database has an outdated FDW remote schema" error

GitLab can error with a `Geo database has an outdated FDW remote schema` message.

For example:

```text
Geo database has an outdated FDW remote schema. It contains 229 of 236 expected tables. Please refer to Geo Troubleshooting.
```

To resolve this, run the following command:

```sh
sudo gitlab-rake geo:db:refresh_foreign_tables
```

## Expired artifacts

If you notice for some reason there are more artifacts on the Geo
secondary node than on the Geo primary node, you can use the rake task
to [cleanup orphan artifact files](../../../raketasks/cleanup.md#remove-orphan-artifact-files).

On a Geo **secondary** node, this command will also clean up all Geo
registry record related to the orphan files on disk.

## Fixing sign in errors

### Message: The redirect URI included is not valid

If you are able to log in to the **primary** node, but you receive this error
when attempting to log into a **secondary**, you should check that the Geo
node's URL matches its external URL.

1. On the primary, visit **Admin Area > Geo**.
1. Find the affected **secondary** and click **Edit**.
1. Ensure the **URL** field matches the value found in `/etc/gitlab/gitlab.rb`
   in `external_url "https://gitlab.example.com"` on the frontend server(s) of
   the **secondary** node.

## Fixing common errors

This section documents common errors reported in the Admin UI and how to fix them.

### Geo database configuration file is missing

GitLab cannot find or doesn't have permission to access the `database_geo.yml` configuration file.

In an Omnibus GitLab installation, the file should be in `/var/opt/gitlab/gitlab-rails/etc`.
If it doesn't exist or inadvertent changes have been made to it, run `sudo gitlab-ctl reconfigure` to restore it to its correct state.

If this path is mounted on a remote volume, please check your volume configuration and that it has correct permissions.

### An existing tracking database cannot be reused

Geo cannot reuse an existing tracking database.

It is safest to use a fresh secondary, or reset the whole secondary by following
[Resetting Geo secondary node replication](#resetting-geo-secondary-node-replication).

### Geo node has a database that is writable which is an indication it is not configured for replication with the primary node

This error refers to a problem with the database replica on a **secondary** node,
which Geo expects to have access to. It usually means, either:

- An unsupported replication method was used (for example, logical replication).
- The instructions to setup a [Geo database replication](database.md) were not followed correctly.

A common source of confusion with **secondary** nodes is that it requires two separate
PostgreSQL instances:

- A read-only replica of the **primary** node.
- A regular, writable instance that holds replication metadata. That is, the Geo tracking database.

### Geo node does not appear to be replicating the database from the primary node

The most common problems that prevent the database from replicating correctly are:

- **Secondary** nodes cannot reach the **primary** node. Check credentials, firewall rules, etc.
- SSL certificate problems. Make sure you copied `/etc/gitlab/gitlab-secrets.json` from the **primary** node.
- Database storage disk is full.
- Database replication slot is misconfigured.
- Database is not using a replication slot or another alternative and cannot catch-up because WAL files were purged.

Make sure you follow the [Geo database replication](database.md) instructions for supported configuration.

### Geo database version (...) does not match latest migration (...)

If you are using GitLab Omnibus installation, something might have failed during upgrade. You can:

- Run `sudo gitlab-ctl reconfigure`.
- Manually trigger the database migration by running: `sudo gitlab-rake geo:db:migrate` as root on the **secondary** node.

### Geo database is not configured to use Foreign Data Wrapper

This error means the Geo Tracking Database doesn't have the FDW server and credentials
configured.

See ["Foreign Data Wrapper (FDW) is not configured" error?](#foreign-data-wrapper-fdw-is-not-configured-error).

### GitLab indicates that more than 100% of repositories were synced

This can be caused by orphaned records in the project registry. You can clear them
[using a Rake task](../../../administration/raketasks/geo.md#remove-orphaned-project-registries).

### Geo Admin Area returns 404 error for a secondary node

Sometimes `sudo gitlab-rake gitlab:geo:check` indicates that the **secondary** node is
healthy, but a 404 error for the **secondary** node is returned in the Geo Admin Area on
the **primary** node.

To resolve this issue:

- Try restarting the **secondary** using `sudo gitlab-ctl restart`.
- Check `/var/log/gitlab/gitlab-rails/geo.log` to see if the **secondary** node is
  using IPv6 to send its status to the **primary** node. If it is, add an entry to
  the **primary** node using IPv4 in the `/etc/hosts` file. Alternatively, you should
  [enable IPv6 on the primary node](https://docs.gitlab.com/omnibus/settings/nginx.html#setting-the-nginx-listen-address-or-addresses).
