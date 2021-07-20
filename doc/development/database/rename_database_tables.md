---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Rename table without downtime

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54354) in GitLab 13.12.

With our database helper methods built into GitLab, it's possible to rename a database table without downtime.

The technique builds on top of database views, using the following steps:

1. Rename the database table.
1. Create a database view using the old table name by pointing to the new table name.
1. Add workaround for ActiveRecord's schema cache.

For example, consider that we are renaming the `issues` table name to `tickets`. Run:

```sql
BEGIN;
  ALTER TABLE issues RENAME TO tickets;
  CREATE VIEW issues AS SELECT * FROM tickets;
COMMIT;
```

As database views do not expose the underlying table schema (default values, not null
constraints, and indexes), we need further steps to update the application to use the new
table name. ActiveRecord heavily relies on this data, for example, to initialize new
models.

To work around this limitation, we need to tell ActiveRecord to acquire this information
from a different table using the new table name.

## Migration strategy breakdown

### Release N.M: Mark the ActiveRecord model's table

Consider the current release as "Release N.M".

In this release, register the database table so that it instructs ActiveRecord to fetch the
database table information (for `SchemaCache`) using the new table name (if it's present). Otherwise, fall back
to the old table name. This is necessary to avoid errors during a zero-downtime deployment.

1. Edit the `TABLES_TO_BE_RENAMED` constant in: `lib/gitlab/database.rb`

   ```ruby
   TABLES_TO_BE_RENAMED = {
     'issues' => 'tickets'
   }.freeze
   ```

Note that, in this release (N.M), the `tickets` database table does not exist yet. This step is preparing for the actual table rename in release N.M+1.

### Release N.M+1: Rename the database table

Consider the next release as "Release N.M".

Execute a standard migration (not a post-migration):

```ruby
  include Gitlab::Database::MigrationHelpers

  def up
    rename_table_safely(:issues, :tickets)
  end

  def down
    undo_rename_table_safely(:issues, :tickets)
  end
```

**Important notes:**

- Let other developers know that the table is going to be renamed.
  - Ping the `@gl-database` group in your merge request.
  - Add a note in the Engineering Week-in-Review document: `table_name` is going to be renamed in N.M. Modifications to this table are not allowed in release N.M and N.M+1.
- The helper method uses the standard `rename_table` helper from Rails for renaming the table.
- The helper renames the sequence and the indexes. Sometimes it diverges from the standard Rails convention
when naming indexes, so there is a possibility that not all indexes are properly renamed. After running
the migration locally, check if there are inconsistently named indexes (`db/structure.sql`). Those can be
renamed manually in a separate migration, which can be also part of the release M.N+1.
- Foreign key columns might still contain the old table name. For smaller tables, follow our [standard column
rename process](../avoiding_downtime_in_migrations.md#renaming-columns)
- Avoid renaming database tables which are using with triggers.
- Table modifications (add or remove columns) are not allowed during the rename process, please make sure that all changes to the table happen before the rename migration is started (or in the next release).
- As the index names might change, verify that the model does not use bulk insert
(for example, `insert_all` and `upsert_all`) with the `unique_by: index_name` option.
Renaming an index while using these methods may break functionality.
- Modify the model code to point to the new database table. Do this by
renaming the model directly or setting the `self.table_name` variable.

At this point, we don't have applications using the old database table name in their queries.

1. Remove the database view through a post-migration:

   ```ruby
     include Gitlab::Database::MigrationHelpers

     def up
       finalize_table_rename(:issues, :tickets)
     end

     def down
       undo_finalize_table_rename(:issues, :tickets)
     end
   ```

1. Additionally the table definition from `TABLES_TO_BE_RENAMED` **must** be removed.

To do so, edit the `TABLES_TO_BE_RENAMED` constant in `lib/gitlab/database.rb`:

   From:

   ```ruby
   TABLES_TO_BE_RENAMED = {
     'issues' => 'tickets'
   }.freeze
   ```

   To:

   ```ruby
   TABLES_TO_BE_RENAMED = {}.freeze
   ```

#### Zero-downtime deployments

When the application is upgraded without downtime, there can be application instances
running the old code. The old code still references the old database table. The queries
still function without any problems, because the backward-compatible database view is
in place.

In case the old version of the application needs to be restarted or reconnected to the
database, ActiveRecord fetches the column information again. At this time, our previously
marked table (`TABLES_TO_BE_RENAMED`) instructs ActiveRecord to use the new database table name
when fetching the database table information.

The new version of the application will use the new database table.
