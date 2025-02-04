---
stage: Data Access
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Deduplicate database records in a database table
---

This guide describes a strategy for introducing database-level uniqueness constraint (unique index) to existing database tables with data.

Requirements:

- Attribute modifications (`INSERT`, `UPDATE`) related to the columns happen only via ActiveRecord (the technique depends on AR callbacks).
- Duplications are rare and mostly happen due to concurrent record creation. This can be verified by checking the production database table via teleport (reach out to a database maintainer for help).

The total runtime mainly depends on the number of records in the database table. The migration will require scanning all records; to fit into the
post-deployment migration runtime limit (about 10 minutes), database table with less than 10 million rows can be considered a small table.

## Deduplication strategy for small tables

The strategy requires 3 milestones. As an example, we're going to deduplicate the `issues` table based on the `title` column where the `title` must be unique for a given `project_id` column.

Milestone 1:

1. Add a new database index (not unique) to the table via post-migration (if not present already).
1. Add model-level uniqueness validation to reduce the likelihood of duplicates (if not present already).
1. Add a transaction-level [advisory lock](https://www.postgresql.org/docs/current/explicit-locking.html#ADVISORY-LOCKS) to prevent creating duplicate records.

The second step on its own will not prevent duplicate records, see the [Rails guides](https://guides.rubyonrails.org/active_record_validations.html#uniqueness) for more information.

Post-migration for creating the index:

```ruby
def up
  add_concurrent_index :issues, [:project_id, :title], name: INDEX_NAME
end

def down
  remove_concurrent_index_by_name :issues, INDEX_NAME
end
```

The `Issue` model validation and the advisory lock:

```ruby
class Issue < ApplicationRecord
  validates :title, uniqueness: { scope: :project_id }
  before_validation :prevent_concurrent_inserts

  private

  # This method will block while another database transaction attempts to insert the same data.
  # After the lock is released by the other transaction, the uniqueness validation may fail
  # with record not unique validation error.

  # Without this block the uniqueness validation wouldn't be able to detect duplicated
  # records as transactions can't see each other's changes.
  def prevent_concurrent_inserts
    return if project_id.nil? || title.nil?

    lock_key = ['issues', project_id, title].join('-')
    lock_expression = "hashtext(#{connection.quote(lock_key)})"
    connection.execute("SELECT pg_advisory_xact_lock(#{lock_expression})")
  end
end
```

Milestone 2:

1. Implement the deduplication logic in a post deployment migration.
1. Replace the existing index with a unique index.

How to resolve duplicates (e.g., merge attributes, keep the most recent record) depends on the features built on top of the database table. In this example, we keep the most recent record.

```ruby
def up
  model = define_batchable_model('issues')

  # Single pass over the table
  model.each_batch do |batch|
    # find duplicated (project_id, title) pairs
    duplicates = model
      .where("(project_id, title) IN (#{batch.select(:project_id, :title).to_sql})")
      .group(:project_id, :title)
      .having('COUNT(*) > 1')
      .pluck(:project_id, :title)

    value_list = Arel::Nodes::ValuesList.new(duplicates).to_sql

    # Locate all records by (project_id, title) pairs and keep the most recent record.
    # The lookup should be fast enough if duplications are rare.
    cleanup_query = <<~SQL
    WITH duplicated_records AS MATERIALIZED (
      SELECT
        id,
        ROW_NUMBER() OVER (PARTITION BY project_id, title ORDER BY project_id, title, id DESC) AS row_number
      FROM issues
      WHERE (project_id, title) IN (#{value_list})
      ORDER BY project_id, title
    )
    DELETE FROM issues
    WHERE id IN (
      SELECT id FROM duplicated_records WHERE row_number > 1
    )
    SQL

    model.connection.execute(cleanup_query)
  end
end

def down
  # no-op
end
```

NOTE:
This is a destructive operation with no possibility of rolling back. Make sure that the deduplication logic is tested thoroughly.

Replacing the old index with a unique index:

```ruby
def up
  add_concurrent_index :issues, [:project_id, :title], name: UNIQUE_INDEX_NAME, unique: true
  remove_concurrent_index_by_name :issues, INDEX_NAME
end

def down
  add_concurrent_index :issues, [:project_id, :title], name: INDEX_NAME
  remove_concurrent_index_by_name :issues, UNIQUE_INDEX_NAME
end
```

Milestone 3:

1. Remove the advisory lock by removing the `prevent_concurrent_inserts` ActiveRecord callback method.

NOTE:
This milestone must be after a [required stop](required_stops.md).

## Deduplicate strategy for large tables

When deduplicating a large table we can move the batching and the deduplication logic into a [batched background migration](batched_background_migrations.md).

Milestone 1:

1. Add a new database index (not unique) to the table via post migration.
1. Add model-level uniqueness validation to reduce the likelihood of duplicates (if not present already).
1. Add a transaction-level [advisory lock](https://www.postgresql.org/docs/current/explicit-locking.html#ADVISORY-LOCKS) to prevent creating duplicate records.

Milestone 2:

1. Implement the deduplication logic in a batched background migration and enqueue it in a post deployment migration.

Milestone 3:

1. Finalize the batched background migration.
1. Replace the existing index with a unique index.
1. Remove the advisory lock by removing the `prevent_concurrent_inserts` ActiveRecord callback method.

NOTE:
This milestone must be after a [required stop](required_stops.md).
