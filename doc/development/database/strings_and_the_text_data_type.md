---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Strings and the Text data type
---

When adding new columns to store strings or other textual information:

1. We always use the `text` data type instead of the `string` data type.
1. `text` columns should always have a limit set, either by using the `create_table` with
   the `#text ... limit: 100` helper (see below) when creating a table, or by using the `add_text_limit`
   when altering an existing table. Without a limit, the longest possible [character string is about 1 GB](https://www.postgresql.org/docs/current/datatype-character.html).

The standard Rails `text` column type cannot be defined with a limit, but we extend `create_table` to
add a `limit: 255` option. Outside of `create_table`, `add_text_limit` can be used to add a [check constraint](https://www.postgresql.org/docs/11/ddl-constraints.html)
to an already existing column.

## Background information

The reason we always want to use `text` instead of `string` is that `string` columns have the
disadvantage that if you want to update their limit, you have to run an `ALTER TABLE ...` command.

While a limit is added, the `ALTER TABLE ...` command requires an `EXCLUSIVE LOCK` on the table, which
is held throughout the process of updating the column and while validating all existing records, a
process that can take a while for large tables.

On the other hand, texts are [more or less equivalent to strings](https://www.depesz.com/2010/03/02/charx-vs-varcharx-vs-varchar-vs-text/) in PostgreSQL,
while having the additional advantage that adding a limit on an existing column or updating their
limit does not require the very costly `EXCLUSIVE LOCK` to be held throughout the validation phase.
We can start by updating the constraint with the valid option off, which requires an `EXCLUSIVE LOCK`
but only for updating the declaration of the columns. We can then validate it at a later step using
`VALIDATE CONSTRAINT`, which requires only a `SHARE UPDATE EXCLUSIVE LOCK` (only conflicts with other
validations and index creation while it allows reads and writes).

NOTE:
Don't use text columns for `attr_encrypted` attributes. Use a
[`:binary` column](../migration_style_guide.md#encrypted-attributes) instead.

## Create a new table with text columns

When adding a new table, the limits for all text columns should be added in the same migration as
the table creation. We add a `limit:` attribute to Rails' `#text` method, which allows adding a limit
for this column.

For example, consider a migration that creates a table with two text columns,
`db/migrate/20200401000001_create_db_guides.rb`:

```ruby
class CreateDbGuides < Gitlab::Database::Migration[2.1]
  def change
    create_table :db_guides do |t|
      t.bigint :stars, default: 0, null: false
      t.text :title, limit: 128
      t.text :notes, limit: 1024
    end
  end
end
```

## Add a text column to an existing table

Adding a column to an existing table requires an exclusive lock for that table. Even though that lock
is held for a brief amount of time, the time `add_column` needs to complete its execution can vary
depending on how frequently the table is accessed. For example, acquiring an exclusive lock for a very
frequently accessed table may take minutes in GitLab.com and requires the use of `with_lock_retries`.

When adding a text limit, transactions must be disabled with `disable_ddl_transaction!`. This means adding the column is not rolled back
in case the migration fails afterwards. An attempt to re-run the migration will raise an error because of the already existing column.

For these reasons, adding a text column to an existing table can be done by either:

- [Add the column and limit in separate migrations.](#add-the-column-and-limit-in-separate-migrations)
- [Add the column and limit in one migration with checking if the column already exists.](#add-the-column-and-limit-in-one-migration-with-checking-if-the-column-already-exists)

### Add the column and limit in separate migrations

Consider a migration that adds a new text column `extended_title` to table `sprints`,
`db/migrate/20200501000001_add_extended_title_to_sprints.rb`:

```ruby
class AddExtendedTitleToSprints < Gitlab::Database::Migration[2.1]

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20200501000002_add_text_limit_to_sprints_extended_title
  def change
    add_column :sprints, :extended_title, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
```

A second migration should follow the first one with a limit added to `extended_title`,
`db/migrate/20200501000002_add_text_limit_to_sprints_extended_title.rb`:

```ruby
class AddTextLimitToSprintsExtendedTitle < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :sprints, :extended_title, 512
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    remove_text_limit :sprints, :extended_title
  end
end
```

### Add the column and limit in one migration with checking if the column already exists

Consider a migration that adds a new text column `extended_title` to table `sprints`,
`db/migrate/20200501000001_add_extended_title_to_sprints.rb`:

```ruby
class AddExtendedTitleToSprints < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :sprints, :extended_title, :text, if_not_exists: true
    end

    add_text_limit :sprints, :extended_title, 512
  end

  def down
    with_lock_retries do
      remove_column :sprints, :extended_title, if_exists: true
    end
  end
end
```

## Add a text limit constraint to an existing column

Adding text limits to existing database columns requires multiple steps split into at least two different releases:

1. Release `N.M` (current release)

   - Add a post-deployment migration to add the limit to the text column with `validate: false`.
   - Add a post-deployment migration to fix the existing records.

     NOTE:
     Depending on the size of the table, a background migration for cleanup could be required in the next release.
     See [text limit constraints on large tables](strings_and_the_text_data_type.md#text-limit-constraints-on-large-tables) for more information.

   - Create an issue for the next milestone to validate the text limit.

1. Release `N.M+1` (next release)

   - Validate the text limit using a post-deployment migration.

### Example

Let's assume we want to add a `1024` limit to `issues.title_html` for a given release milestone,
such as 13.0.

Issues is a pretty busy and large table with more than 25 million rows, so we don't want to lock all
other processes that try to access it while running the update.

Also, after checking our production database, we know that there are `issues` with more characters in
their title than the 1024 character limit, so we cannot add and validate the constraint in one step.

NOTE:
Even if we did not have any record with a title larger than the provided limit, another
instance of GitLab could have such records, so we would follow the same process either way.

#### Prevent new invalid records (current release)

We first add the limit as a `NOT VALID` check constraint to the table, which enforces consistency when
new records are inserted or current records are updated.

In the example above, the existing issues with more than 1024 characters in their title are not
affected, and you are still able to update records in the `issues` table. However, when you'd try
to update the `title_html` with a title that has more than 1024 characters, the constraint causes
a database error.

Adding or removing a constraint to an existing attribute requires that any application changes are
deployed _first_,
otherwise servers still in the old version of the application
[may try to update the attribute with invalid values](../multi_version_compatibility.md#ci-artifact-uploads-were-failing).
For these reasons, `add_text_limit` should run in a post-deployment migration.

Still in our example, for the 13.0 milestone (current), consider that the following validation
has been added to model `Issue`:

```ruby
validates :title_html, length: { maximum: 1024 }
```

We can also update the database in the same milestone by adding the text limit with `validate: false`
in a post-deployment migration,
`db/post_migrate/20200501000001_add_text_limit_migration.rb`:

```ruby
class AddTextLimitMigration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # This will add the constraint WITHOUT validating it
    add_text_limit :issues, :title_html, 1024, validate: false
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    remove_text_limit :issues, :title_html
  end
end
```

#### Data migration to fix existing records (current release)

The approach here depends on the data volume and the cleanup strategy. The number of records that must
be fixed on GitLab.com is a nice indicator that helps us decide whether to use a post-deployment
migration or a background data migration:

- If the data volume is less than `1,000` records, then the data migration can be executed within the post-migration.
- If the data volume is higher than `1,000` records, it's advised to create a background migration.

When unsure about which option to use, contact the Database team for advice.

Back to our example, the issues table is considerably large and frequently accessed, so we are going
to add a background migration for the 13.0 milestone (current),
`db/post_migrate/20200501000002_schedule_cap_title_length_on_issues.rb`:

```ruby
class ScheduleCapTitleLengthOnIssues < Gitlab::Database::Migration[2.1]
  # Info on how many records will be affected on GitLab.com
  # time each batch needs to run on average, etc ...
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 2.minutes.to_i

  # Background migration will update issues whose title is longer than 1024 limit
  ISSUES_BACKGROUND_MIGRATION = 'CapTitleLengthOnIssues'.freeze

  disable_ddl_transaction!

  def up
    queue_batched_background_migration(
      ISSUES_BACKGROUND_MIGRATION,
      :issues,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(ISSUES_BACKGROUND_MIGRATION, :issues, :id, [])
  end
end
```

To keep this guide short, we skipped the definition of the background migration and only
provided a high level example of the post-deployment migration that is used to schedule the batches.
You can find more information on the guide about [batched background migrations](batched_background_migrations.md)

#### Validate the text limit (next release)

Validating the text limit scans the whole table, and makes sure that each record is correct.

Still in our example, for the 13.1 milestone (next), we run the `validate_text_limit` migration
helper in a final post-deployment migration,
`db/post_migrate/20200601000001_validate_text_limit_migration.rb`:

```ruby
class ValidateTextLimitMigration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    validate_text_limit :issues, :title_html
  end

  def down
    # no-op
  end
end
```

## Increasing a text limit constraint on an existing column

Increasing text limits on existing database columns can be safely achieved by first adding the new limit (with a different name),
and then dropping the previous limit:

```ruby
class ChangeMaintainerNoteLimitInCiRunner < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :ci_runners, :maintainer_note, 1024, constraint_name: check_constraint_name(:ci_runners, :maintainer_note, 'max_length_1K')
    remove_text_limit :ci_runners, :maintainer_note, constraint_name: check_constraint_name(:ci_runners, :maintainer_note, 'max_length')
  end

  def down
    # no-op: Danger of failing if there are records with length(maintainer_note) > 255
  end
end
```

## Text limit constraints on large tables

If you have to clean up a text column for a really [large table](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml#L3)
(for example, the `artifacts` in `ci_builds`), your background migration goes on for a while and
it needs an additional [batched background migration cleaning up](batched_background_migrations.md#cleaning-up-a-batched-background-migration)
in the release after adding the data migration.

In that rare case you need 3 releases end-to-end:

1. Release `N.M` - Add the text limit and the background migration to fix the existing records.
1. Release `N.M+1` - Cleanup the background migration.
1. Release `N.M+2` - Validate the text limit.
