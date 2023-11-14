---
stage: Data Stores
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Troubleshooting and debugging the database

This section is to help give some copy-pasta you can use as a reference when you
run into some head-banging database problems.

A first step is to search for your error in Slack, or search for `GitLab <my error>` with Google.

Available `RAILS_ENV`:

- `production` (generally not for your main GDK database, but you may need this for other installations such as Omnibus).
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

- `bundle exec rake db:migrate RAILS_ENV=development`: Execute any pending migrations that you may have picked up from a MR
- `bundle exec rake db:migrate:status RAILS_ENV=development`: Check if all migrations are `up` or `down`
- `bundle exec rake db:migrate:down:main VERSION=20170926203418 RAILS_ENV=development`: Tear down a migration
- `bundle exec rake db:migrate:up:main VERSION=20170926203418 RAILS_ENV=development`: Set up a migration
- `bundle exec rake db:migrate:redo:main VERSION=20170926203418 RAILS_ENV=development`: Re-run a specific migration

Replace `main` in the above commands to execute against the `ci` database instead of `main`.

## Manually access the database

Access the database via one of these commands (they all get you to the same place)

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
   Alternatively, you can use the connection string `postgresql://localhost:5432/gitlabhq_development`.

The new connection should be working now.

## Access the GDK database with Visual Studio Code

Use these instructions for exploring the GitLab database while developing with the GDK:

1. Install or open [Visual Studio Code](https://code.visualstudio.com/download).
1. Install the [PostgreSQL VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ckolkman.vscode-postgres).
1. In Visual Studio Code select **PostgreSQL Explorer** in the left toolbar.
1. In the top bar of the new window, select `+` to **Add Database Connection**, and follow the prompts to fill in the details:
   1. **Hostname**: the path to the PostgreSQL folder in your GDK directory (for example `/dev/gitlab-development-kit/postgresql`).
   1. **PostgreSQL user to authenticate as**: usually your local username, unless otherwise specified during PostgreSQL installation.
   1. **Password of the PostgreSQL user**: the password you set when installing PostgreSQL.
   1. **Port number to connect to**: `5432` (default).
   1. **Use an SSL connection?** This depends on your installation. Options are:
      - **Use Secure Connection**
      - **Standard Connection** (default)
   1. **Optional. The database to connect to**: `gitlabhq_development`.
   1. **The display name for the database connection**: `gitlabhq_development`.

Your database connection should now be displayed in the PostgreSQL Explorer pane and
you can explore the `gitlabhq_development` database. If you cannot connect, ensure
that GDK is running. For further instructions on how to use the PostgreSQL Explorer
Extension for Visual Studio Code, read the [usage section](https://marketplace.visualstudio.com/items?itemName=ckolkman.vscode-postgres#usage)
of the extension documentation.

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

In some cases you may want to bypass this check. For example, if you were on a version
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
