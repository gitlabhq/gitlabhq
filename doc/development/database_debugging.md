# Database Debugging and Troubleshooting

This section is to help give some copy-pasta you can use as a reference when you
run into some head-banging database problems.

An easy first step is to search for your error in Slack, or search for `GitLab <my error>` with Google.

---

Available `RAILS_ENV`

- `production` (generally not for your main GDK db, but you may need this for e.g. Omnibus)
- `development` (this is your main GDK db)
- `test` (used for tests like rspec)

## Nuke everything and start over

If you just want to delete everything and start over with an empty DB (~1 minute):

- `bundle exec rake db:reset RAILS_ENV=development`

If you just want to delete everything and start over with dummy data (~4 minutes). This also does `db:reset` and runs DB-specific migrations:

- `bundle exec rake dev:setup RAILS_ENV=development`

If your test DB is giving you problems, it is safe to nuke it because it doesn't contain important data:

- `bundle exec rake db:reset RAILS_ENV=test`

## Migration wrangling

- `bundle exec rake db:migrate RAILS_ENV=development`: Execute any pending migrations that you may have picked up from a MR
- `bundle exec rake db:migrate:status RAILS_ENV=development`: Check if all migrations are `up` or `down`
- `bundle exec rake db:migrate:down VERSION=20170926203418 RAILS_ENV=development`: Tear down a migration
- `bundle exec rake db:migrate:up VERSION=20170926203418 RAILS_ENV=development`: Set up a migration
- `bundle exec rake db:migrate:redo VERSION=20170926203418 RAILS_ENV=development`: Re-run a specific migration

## Manually access the database

Access the database via one of these commands (they all get you to the same place)

```
gdk psql -d gitlabhq_development
bundle exec rails dbconsole RAILS_ENV=development
bundle exec rails db RAILS_ENV=development
```

- `\q`: Quit/exit
- `\dt`: List all tables
- `\d+ issues`: List columns for `issues` table
- `CREATE TABLE board_labels();`: Create a table called `board_labels`
- `SELECT * FROM schema_migrations WHERE version = '20170926203418';`: Check if a migration was run
- `DELETE FROM schema_migrations WHERE version = '20170926203418';`: Manually remove a migration

## FAQ

### `ActiveRecord::PendingMigrationError` with Spring

When running specs with the [Spring preloader](rake_tasks.md#speed-up-tests-rake-tasks-and-migrations),
the test database can get into a corrupted state. Trying to run the migration or
dropping/resetting the test database has no effect.

```sh
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

```sh
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
to an older migration, from before. In this case, in order to migrate forward again,
you should set the `SKIP_SCHEMA_VERSION_CHECK` environment variable.

```sh
bundle exec rake db:migrate SKIP_SCHEMA_VERSION_CHECK=true
```
