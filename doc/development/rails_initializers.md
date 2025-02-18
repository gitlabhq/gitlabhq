---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
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

To prevent this, we stop database connections from being opened during
routes loading. Doing will result in an error:

```shell
RuntimeError:
  Database connection should not be called during initializers.
# ./config/initializers/00_connection_logger.rb:15:in `new_client'
# ./lib/gitlab/database/load_balancing/load_balancer.rb:112:in `block in read_write'
# ./lib/gitlab/database/load_balancing/load_balancer.rb:184:in `retry_with_backoff'
# ./lib/gitlab/database/load_balancing/load_balancer.rb:111:in `read_write'
# ./lib/gitlab/database/load_balancing/connection_proxy.rb:119:in `write_using_load_balancer'
# ./lib/gitlab/database/load_balancing/connection_proxy.rb:89:in `method_missing'
# ./config/routes.rb:10:in `block in <main>'
# ./config/routes.rb:9:in `<main>'
```
