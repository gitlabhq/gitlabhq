---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Troubleshooting and debugging the database
---

This section is to help give some copy-pasta you can use as a reference when you
run into some head-banging database problems.

A first step is to search for your error in Slack, or search for `GitLab <my error>` with Google.

Available `RAILS_ENV`:

- `production` (generally not for your main GDK database, but you might need this for other installations such as Omnibus).
- `development` (this is your main GDK db).
- `test` (used for tests like RSpec).

## Delete everything and start over

If you just want to delete everything and start over with an empty DB (approximately 1 minute):

```shell
bundle exec rake db:reset RAILS_ENV=development
```

If you want to seed the empty DB with sample data (approximately 4 minutes):

```shell
bundle exec rake dev:setup
```

If you just want to delete everything and start over with sample data (approximately 4 minutes). This
also does `db:reset` and runs DB-specific migrations:

```shell
bundle exec rake db:setup RAILS_ENV=development
```

If your test DB is giving you problems, it is safe to delete everything because it doesn't contain important
data:

```shell
bundle exec rake db:reset RAILS_ENV=test
```

## Migration wrangling

- `bundle exec rake db:migrate RAILS_ENV=development`: Execute any pending migrations that you might have picked up from a MR
- `bundle exec rake db:migrate:status RAILS_ENV=development`: Check if all migrations are `up` or `down`
- `bundle exec rake db:migrate:down:main VERSION=20170926203418 RAILS_ENV=development`: Tear down a migration
- `bundle exec rake db:migrate:up:main VERSION=20170926203418 RAILS_ENV=development`: Set up a migration
- `bundle exec rake db:migrate:redo:main VERSION=20170926203418 RAILS_ENV=development`: Re-run a specific migration

Replace `main` in the above commands to execute against the `ci` database instead of `main`.

## Manually access the database

Access the database with one of these commands. They all get you to the same place.

```shell
gdk psql -d gitlabhq_development
bundle exec rails dbconsole -e development
bundle exec rails db -e development
```

- `\q`: Quit/exit
- `\dt`: List all tables
- `\d+ issues`: List columns for `issues` table
- `CREATE TABLE board_labels();`: Create a table called `board_labels`
- `SELECT * FROM schema_migrations WHERE version = '20170926203418';`: Check if a migration was run
- `DELETE FROM schema_migrations WHERE version = '20170926203418';`: Manually remove a migration

## Access the database with a GUI

Most GUIs (DataGrip, RubyMine, DBeaver) require a TCP connection to the database, but by default
the database runs on a UNIX socket. To be able to access the database from these tools, some steps
are needed:

1. On the GDK root directory, run:

   ```shell
   gdk config set postgresql.host localhost
   ```

1. Open your `gdk.yml`, and confirm that it has the following lines:

   ```yaml
   postgresql:
      host: localhost
   ```

1. Reconfigure GDK:

   ```shell
   gdk reconfigure
   ```

1. On your database GUI, select `localhost` as host, `5432` as port and `gitlabhq_development` as database.
   You can also use the connection string `postgresql://localhost:5432/gitlabhq_development`.

The new connection should be working now.

## Access the GDK database with Visual Studio Code

Create a database connection using the PostgreSQL extension in Visual Studio Code to access and
explore the GDK database.

Prerequisites:

- [Visual Studio (VS) Code](https://code.visualstudio.com/download).
- [PostgreSQL](https://marketplace.visualstudio.com/items?itemName=ckolkman.vscode-postgres) VS Code extension.

To create a database connection:

1. In the activity bar, select the **PostgreSQL Explorer** icon.
1. From the opened pane, select **+** to add a new database connection:
1. Enter the **hostname** of the database. Use the path to the PostgreSQL folder in your GDK directory.
   - Example: `/dev/gitlab-development-kit/postgresql`
1. Enter a **PostgreSQL user to authenticate as**.
   Use your local username unless otherwise specified during PostgreSQL installation.
   To verify your PostgreSQL username:
   1. Ensure you are in the `gitlab` directory.
   1. Access the PostgreSQL database. Run `rails db`. The output should look like:

         ```shell
         psql (14.9)
         Type "help" for help.

         gitlabhq_development=#
         ```

   1. In the returned PostgreSQL prompt, run `\conninfo` to display the connected user and
      the port used to establish the connection. For example:

         ```shell
         You are connected to database "gitlabhq_development" as user "root" on host "localhost" (address "127.0.0.1") at port "5432".
         ```

1. When prompted to enter the **password of the PostgreSQL user**, enter the password you set or leave the field blank.
   - As you are logged in to the same machine that the Postgres server is running on, a password is not required.
1. Enter**Port number to connect to**. The default port number is`5432`.
1. In the **use an SSL connection?** field, select the appropriate connection for your
installation. The options are:
   - **Use Secure Connection**
   - **Standard Connection** (default)
1. In the optional **database to connect to** field, enter `gitlabhq_development`.
1. In the **display name for the database connection** field, enter `gitlabhq_development`.

Your `gitlabhq_development` database connection is now displayed in the **PostgreSQL Explorer** pane.
Use the arrows to expand and explore the contents of the GDK database.

If you cannot connect, first ensure that GDK is running and try again. For further instructions on how
to use the PostgreSQL Explorer extension for VS Code, see
the [usage section](https://marketplace.visualstudio.com/items?itemName=ckolkman.vscode-postgres#usage)
of the extension's documentation.

## FAQ

### `ActiveRecord::PendingMigrationError` with Spring

When running specs with the [Spring pre-loader](../rake_tasks.md#speed-up-tests-rake-tasks-and-migrations),
the test database can get into a corrupted state. Trying to run the migration or
dropping/resetting the test database has no effect.

```shell
$ bundle exec spring rspec some_spec.rb
...
Failure/Error: ActiveRecord::Migration.maintain_test_schema!

ActiveRecord::PendingMigrationError:


  Migrations are pending. To resolve this issue, run:

    bin/rake db:migrate RAILS_ENV=test
# ~/.rvm/gems/ruby-2.3.3/gems/activerecord-4.2.10/lib/active_record/migration.rb:392:in `check_pending!'
...
0 examples, 0 failures, 1 error occurred outside of examples
```

To resolve, you can kill the spring server and app that lives between spec runs.

```shell
$ ps aux | grep spring
eric             87304   1.3  2.9  3080836 482596   ??  Ss   10:12AM   4:08.36 spring app    | gitlab | started 6 hours ago | test mode
eric             37709   0.0  0.0  2518640   7524 s006  S    Wed11AM   0:00.79 spring server | gitlab | started 29 hours ago
$ kill 87304
$ kill 37709
```

### db:migrate `database version is too old to be migrated` error

Users receive this error when `db:migrate` detects that the current schema version
is older than the `MIN_SCHEMA_VERSION` defined in the `Gitlab::Database` library
module.

Over time we cleanup/combine old migrations in the codebase, so it is not always
possible to migrate GitLab from every previous version.

In some cases you might want to bypass this check. For example, if you were on a version
of GitLab schema later than the `MIN_SCHEMA_VERSION`, and then rolled back the
to an older migration, from before. In this case, to migrate forward again,
you should set the `SKIP_SCHEMA_VERSION_CHECK` environment variable.

```shell
bundle exec rake db:migrate SKIP_SCHEMA_VERSION_CHECK=true
```

## Performance issues

### Reduce connection overhead with connection pooling

Creating new database connections is not free, and in PostgreSQL specifically, it requires
forking an entire process to handle each new one. In case a connection lives for a very long time,
this is no problem. However, forking a process for several small queries can turn out to be costly.
If left unattended, peaks of new database connections can cause performance degradation,
or even lead to a complete outage.

A proven solution for instances that deal with surges of small, short-lived database connections
is to implement [PgBouncer](../../administration/postgresql/pgbouncer.md#pgbouncer-as-part-of-a-fault-tolerant-gitlab-installation) as a connection pooler.
This pool can be used to hold thousands of connections for almost no overhead. The drawback is the addition of
a small amount of latency, in exchange for up to more than 90% performance improvement, depending on the usage patterns.

PgBouncer can be fine-tuned to fit different installations. See our documentation on
[fine-tuning PgBouncer](../../administration/postgresql/pgbouncer.md#fine-tuning) for more information.

### Run ANALYZE to regenerate database statistics

The `ANALYZE` command is a good first approach for solving many performance issues.
By regenerating table statistics, the query planner creates more efficient query execution paths.

Up to date statistics never hurt!

- For Linux packages, run:

  ```shell
  gitlab-psql -c 'SET statement_timeout = 0; ANALYZE VERBOSE;'
  ```

- On the SQL prompt, run:

  ```sql
  -- needed because this is likely to run longer than the default statement_timeout
  SET statement_timeout = 0;
  ANALYZE VERBOSE;
  ```

### Collect data on ACTIVE workload

Active queries are the only ones actually consuming significant resources from the database.

This query gathers meta information from all existing **active** queries, along with:

- their age
- originating service
- `wait_event` (if it's in the waiting state)
- other possibly relevant information:

```sql
-- long queries are usually easier to read with the fields arranged vertically
\x

SELECT
    pid
    ,datname
    ,usename
    ,application_name
    ,client_hostname
    ,backend_start
    ,query_start
    ,query
    ,age(now(), query_start) AS "age"
    ,state
    ,wait_event
    ,wait_event_type
    ,backend_type
FROM pg_stat_activity
WHERE state = 'active';
```

This query captures a single snapshot, so consider running the query 3-5 times
in a few minutes while the environment is unresponsive:

```sql
-- redirect output to a file
-- this location must be writable by `gitlab-psql`
\o /tmp/active1304.out
--
-- now execute the query above
--
-- all output goes to the file - if the prompt is = then it ran
-- cancel writing output
\o
```

[This Python script](https://gitlab.com/-/snippets/3680015) can help you parse the
output of `pg_stat_activity` into numbers that are easier to understand and correlate to performance issues.

### Investigate queries that seem slow

When you identify a query is taking too long to finish, or hogging too much database resources,
check how the query planner is executing it with `EXPLAIN`:

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT ... FROM ...
```

`BUFFERS` also show approximately how much memory is involved. I/O might cause
the problem, so make sure to add `BUFFERS` when running `EXPLAIN`.

If the database is sometimes performant, and sometimes slow, capture this output
for the same queries while the environment is in either state.

### Investigate index bloat

Index bloat shouldn't typically cause noticeable performance problems, but it can lead to high disk usage, particularly if there are [autovacuum issues](https://gitlab.com/gitlab-org/gitlab/-/issues/412672#note_1401807864).

The query below calculates bloat percentage from PostgreSQL's own `postgres_index_bloat_estimates`
table, and orders the results by percentage value. PostgresSQL needs some amount of
bloat to run correctly, so around 25% still represents standard behavior.

```sql
select  a.identifier, a.bloat_size_bytes, b.tablename, b.ondisk_size_bytes,
    (a.bloat_size_bytes/b.ondisk_size_bytes::float)*100 as percentage
from postgres_index_bloat_estimates a
join postgres_indexes b on a.identifier=b.identifier
where
   -- to ensure the percentage calculation doesn't encounter zeroes
   a.bloat_size_bytes>0 and
   b.ondisk_size_bytes>1000000000
order by  percentage desc;
```

### Rebuild indexes

If you identify a bloated table, you can rebuild its indexes using the query below.
You should also re-run [ANALYZE](#run-analyze-to-regenerate-database-statistics)
afterward, as statistics can be reset after indexes are rebuilt.

```sql
SET statement_timeout = 0;
REINDEX TABLE CONCURRENTLY <table_name>;
```

Monitor the index rebuild process by running the query below with `\watch 30` added after the semicolon:

```sql
SELECT
  t.tablename, indexname, c.reltuples AS num_rows,
  pg_size_pretty(pg_relation_size(quote_ident(t.tablename)::text)) AS table_size,
  pg_size_pretty(pg_relation_size(quote_ident(indexrelname)::text)) AS index_size,
CASE WHEN indisvalid THEN 'Y'
  ELSE 'N'
END AS VALID
FROM pg_tables t
LEFT OUTER JOIN pg_class c ON t.tablename=c.relname
LEFT OUTER JOIN
  ( SELECT c.relname AS ctablename, ipg.relname AS indexname, x.indnatts AS
  number_of_columns, indexrelname, indisvalid FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class ipg ON ipg.oid = x.indexrelid
JOIN pg_stat_all_indexes psai ON x.indexrelid = psai.indexrelid )
AS foo
ON t.tablename = foo.ctablename
WHERE
  t.tablename in ('<comma_separated_table_names>')
  ORDER BY 1,2; \watch 30
```
