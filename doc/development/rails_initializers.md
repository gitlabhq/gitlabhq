---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Rails initializers
---

Initializers are executed when the Rails process is started. That means that initializers are also executed during every deploy.

By default, Rails loads Zeitwerk after the initializers in `config/initializers` are loaded.
Autoloading before Zeitwerk is loaded is now deprecated but because we use a lot of autoloaded
constants in our initializers, we had to move the loading of Zeitwerk earlier than these
initializers.

A side-effect of this is that in the initializers, `config.autoload_paths` is already frozen.

To run an initializer before Zeitwerk is loaded, you need put them in `config/initializers_before_autoloader`.
Ruby files in this folder are loaded in alphabetical order just like the default Rails initializers.

Some examples where you would need to do this are:

1. Modifying Rails' `config.autoload_paths`
1. Changing configuration that Zeitwerk uses, for example, inflections

## Database connections in initializers

Ideally, database connections are not opened from Rails initializers. Opening a
database connection (for example, checking the database exists, or making a database
query) from an initializer means that tasks like `db:drop`, and
`db:test:prepare` will fail because an active session prevents the database from
being dropped.

To enforce this:

1. We run the `clear_active_connections_again` initializer to ensure no database
   connections remain active after initialization.
1. We do not allow database queries in routes. Initializers
   should be static and fast; issuing queries slows down boot time and can cause
   subtle failures.

If a database query is made while loading routes, a warning is printed to STDOUT
with the query and a backtrace, for example:

```shell
InitializerConnections Query: SELECT "projects".* FROM "projects" WHERE "projects"."id" = 1 LIMIT 1
InitializerConnections Backtrace: config/routes.rb:15:in `block (2 levels) in <main>'
InitializerConnections Backtrace: config/routes.rb:9:in `block in <main>'
InitializerConnections Backtrace: lib/initializer_connections.rb:18:in `warn_if_database_connection'
InitializerConnections Backtrace: config/routes.rb:6:in `<main>'
See https://docs.gitlab.com/development/rails_initializers/#database-connections-in-initializers
```
