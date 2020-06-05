# Strings and the Text data type

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30453) in GitLab 13.0.

When adding new columns that will be used to store strings or other textual information:

1. We always use the `text` data type instead of the `string` data type.
1. `text` columns should always have a limit set by using the `add_text_limit` migration helper.

The `text` data type can not be defined with a limit, so `add_text_limit` is enforcing that by
adding a [check constraint](https://www.postgresql.org/docs/11/ddl-constraints.html) on the
column and then validating it at a followup step.

## Background info

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

## Create a new table with text columns

When adding a new table, the limits for all text columns should be added in the same migration as
the table creation.

For example, consider a migration that creates a table with two text columns,
`db/migrate/20200401000001_create_db_guides.rb`:

```ruby
class CreateDbGuides < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:db_guides)
      create_table :db_guides do |t|
        t.bigint :stars, default: 0, null: false
        t.text :title
        t.text :notes
      end
    end

    # The following add the constraints and validate them immediately (no data in the table)
    add_text_limit :db_guides, :title, 128
    add_text_limit :db_guides, :notes, 1024
  end

  def down
    # No need to drop the constraints, drop_table takes care of everything
    drop_table :db_guides
  end
end
```

Adding a check constraint requires an exclusive lock while the `ALTER TABLE` that adds is running.
As we don't want the exclusive lock to be held for the duration of a transaction, `add_text_limit`
must always run in a migration with `disable_ddl_transaction!`.

Also, note that we have to add a check that the table exists so that the migration can be repeated
in case of a failure.

## Add a text column to an existing table

Adding a column to an existing table requires an exclusive lock for that table. Even though that lock
is held for a brief amount of time, the time `add_column` needs to complete its execution can vary
depending on how frequently the table is accessed. For example, acquiring an exclusive lock for a very
frequently accessed table may take minutes in GitLab.com and requires the use of `with_lock_retries`.

For these reasons, it is advised to add the text limit on a separate migration than the `add_column` one.

For example, consider a migration that adds a new text column `extended_title` to table `sprints`,
`db/migrate/20200501000001_add_extended_title_to_sprints.rb`:

```ruby
class AddExtendedTitleToSprints < ActiveRecord::Migration[6.0]
  DOWNTIME = false

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
class AddTextLimitToSprintsExtendedTitle < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

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

## Add a text limit constraint to an existing column

Adding text limits to existing database columns requires multiple steps split into at least two different releases:

1. Release `N.M` (current release)

   - Add a post-deployment migration to add the limit to the text column with `validate: false`.
   - Add a post-deployment migration to fix the existing records.

     NOTE: **Note:**
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
their title than the 1024 character limit, so we can not add and validate the constraint in one step.

NOTE: **Note:**
Even if we did not have any record with a title larger than the provided limit, another
instance of GitLab could have such records, so we would follow the same process either way.

#### Prevent new invalid records (current release)

We first add the limit as a `NOT VALID` check constraint to the table, which enforces consistency when
new records are inserted or current records are updated.

In the example above, the existing issues with more than 1024 characters in their title will not be
affected and you'll be still able to update records in the `issues` table. However, when you'd try
to update the `title_html` with a title that has more than 1024 characters, the constraint causes
a database error.

Adding or removing a constraint to an existing attribute requires that any application changes are
deployed _first_, [otherwise servers still in the old version of the application may try to update the
attribute with invalid values](../multi_version_compatibility.md#ci-artifact-uploads-were-failing).
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
class AddTextLimitMigration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

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
be fixed on GitLab.com is a nice indicator that will help us decide whether to use a post-deployment
migration or a background data migration:

- If the data volume is less than `1,000` records, then the data migration can be executed within the post-migration.
- If the data volume is higher than `1,000` records, it's advised to create a background migration.

When unsure about which option to use, please contact the Database team for advice.

Back to our example, the issues table is considerably large and frequently accessed, so we are going
to add a background migration for the 13.0 milestone (current),
`db/post_migrate/20200501000002_schedule_cap_title_length_on_issues.rb`:

```ruby
class ScheduleCapTitleLengthOnIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Info on how many records will be affected on GitLab.com
  # time each batch needs to run on average, etc ...
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 2.minutes.to_i

  # Background migration will update issues whose title is longer than 1024 limit
  ISSUES_BACKGROUND_MIGRATION = 'CapTitleLengthOnIssues'.freeze

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Issue.where('char_length(title_html) > 1024'),
      ISSUES_MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op : the part of the title_html after the limit is lost forever
  end
end
```

To keep this guide short, we skipped the definition of the background migration and only
provided a high level example of the post-deployment migration that is used to schedule the batches.
You can find more info on the guide about [background migrations](../background_migrations.md)

#### Validate the text limit (next release)

Validating the text limit will scan the whole table and make sure that each record is correct.

Still in our example, for the 13.1 milestone (next), we run the `validate_text_limit` migration
helper in a final post-deployment migration,
`db/post_migrate/20200601000001_validate_text_limit_migration.rb`:

```ruby
class ValidateTextLimitMigration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_text_limit :issues, :title_html
  end

  def down
    # no-op
  end
end
```

## Text limit constraints on large tables

If you have to clean up a text column for a really [large table](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/migration_helpers.rb#L12)
(for example, the `artifacts` in `ci_builds`), your background migration will go on for a while and
it will need an additional [background migration cleaning up](../background_migrations.md#cleaning-up)
in the release after adding the data migration.

In that rare case you will need 3 releases end-to-end:

1. Release `N.M` - Add the text limit and the background migration to fix the existing records.
1. Release `N.M+1` - Cleanup the background migration.
1. Release `N.M+2` - Validate the text limit.
