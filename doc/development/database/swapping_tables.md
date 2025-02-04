---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Swapping Tables
---

Sometimes you need to replace one table with another. For example, when
migrating data in a very large table it's often better to create a copy of the
table and insert & migrate the data into this new table in the background.

Let's say you want to swap the table `events` with `events_for_migration`. In
this case you need to follow 3 steps:

1. Rename `events` to `events_temporary`
1. Rename `events_for_migration` to `events`
1. Rename `events_temporary` to `events_for_migration`

Rails allows you to do this using the `rename_table` method:

```ruby
rename_table :events, :events_temporary
rename_table :events_for_migration, :events
rename_table :events_temporary, :events_for_migration
```

This does not require any downtime as long as the 3 `rename_table` calls are
executed in the _same_ database transaction. Rails by default uses database
transactions for migrations, but if it doesn't you need to start one
manually:

```ruby
Event.transaction do
  rename_table :events, :events_temporary
  rename_table :events_for_migration, :events
  rename_table :events_temporary, :events_for_migration
end
```

Once swapped you _have to_ reset the primary key of the new table. For
PostgreSQL you can use the `reset_pk_sequence!` method like so:

```ruby
reset_pk_sequence!('events')
```

Failure to reset the primary keys results in newly created rows starting
with an ID value of 1. Depending on the existing data this can then lead to
duplicate key constraints from popping up, preventing users from creating new
data.
