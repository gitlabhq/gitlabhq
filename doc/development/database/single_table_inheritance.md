---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Single Table Inheritance
---

**Summary:** Don't design new tables using Single Table Inheritance (STI). For existing tables that use STI as a pattern, avoid adding new types, and consider splitting them into separate tables.

STI is a database design pattern where a single table stores
different types of records. These records have a subset of shared columns and another column
that instructs the application which object that record should be represented by.
This can be used to for example store two different types of SSH keys in the same
table. ActiveRecord makes use of it and provides some features that make STI usage
more convenient.

We no longer allow new STI tables because they:

- Lead to tables with large number of rows, when we should strive to keep tables small.
- Need additional indexes, increasing our usage of lightweight locks, whose saturation can cause incidents.
- Add overhead by having to filter all of the data by a value, leading to more page accesses on read.
- Use the `class_name` to load the correct class for an object, but storing
  the class name is costly and unnecessary.

Instead of using STI, consider the following alternatives:

- Use a different table for each type.
- Avoid adding `*_type` columns. This is a code smell that might indicate that new types will be added in the future, and refactoring in the future will be much harder.
- If you already have a table that is effectively an STI on a `_type` column, consider:
  - Splitting the existent data into multiple tables.
  - Refactoring so that new types can be added as new tables while keeping existing ones (for example, move logic of the base class into a concern).

If, **after considering all of the above downsides and alternatives**, STI
is the only solution for the problem at hand, we can at least avoid the
issues with saving the class name in the record by using an enum type
instead and the `EnumInheritance` concern:

```ruby
class Animal < ActiveRecord::Base
  include EnumInheritance

  enum species: {
    dog: 1,
    cat: 2
  }

  def self.inheritance_column_to_class_map = {
    dog: 'Dog',
    cat: 'Cat'
  }

  def self.inheritance_column = 'species'
end

class Dog < Animal
  self.allow_legacy_sti_class = true
end

class Cat < Animal
  self.allow_legacy_sti_class = true
end
```

If your table already has a `*_type`, new classes for the different types can be added as needed.

## In migrations

Whenever a model is used in a migration, single table inheritance should be disabled.
Due to the way Rails loads associations (even in migrations), failing to disable STI
could result in loading unexpected code or associations which may cause unintended
side effects or failures during upgrades.

```ruby
class SomeMigration < Gitlab::Database::Migration[2.1]
  class Services < MigrationRecord
    self.table_name = 'services'
    self.inheritance_column = :_type_disabled
  end

  def up
  ...
```

If nothing needs to be added to the model other than disabling STI or `EachBatch`,
use the helper `define_batchable_model` instead of defining the class.
This ensures that the migration loads the columns for the migration in isolation,
and the helper disables STI by default.

```ruby
class EnqueueSomeBackgroundMigration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    define_batchable_model('services').select(:id).in_batches do |relation|
      jobs = relation.pluck(:id).map do |id|
        ['ExtractServicesUrl', [id]]
      end

      BackgroundMigrationWorker.bulk_perform_async(jobs)
    end
  end
  ...
```
