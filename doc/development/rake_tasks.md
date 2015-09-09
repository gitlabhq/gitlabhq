# Rake tasks for developers

## Setup db with developer seeds

Note that if your db user does not have advanced privileges you must create the db manually before running this command.

```
bundle exec rake setup
```

The `setup` task is a alias for `gitlab:setup`.
This tasks calls `db:setup` to create the database, calls `add_limits_mysql` that adds limits to the database schema in case of a MySQL database and fianlly it calls `db:seed_fu` to seed the database.
Note: `db:setup` calls `db:seed` but this does nothing.

## Run tests

This runs all test suites present in GitLab.

```
bundle exec rake test
```

## Generate searchable docs for source code

You can find results under the `doc/code` directory.

```
bundle exec rake gitlab:generate_docs
```

## Generate API documentation for project services (e.g. Slack)

```
bundle exec rake services:doc
```
