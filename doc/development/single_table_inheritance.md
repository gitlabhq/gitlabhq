---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Single Table Inheritance

**Summary:** don't use Single Table Inheritance (STI), use separate tables
instead.

Rails makes it possible to have multiple models stored in the same table and map
these rows to the correct models using a `type` column. This can be used to for
example store two different types of SSH keys in the same table.

While tempting to use one should avoid this at all costs for the same reasons as
outlined in the document ["Polymorphic Associations"](polymorphic_associations.md).

## Solution

The solution is very simple: just use a separate table for every type you'd
otherwise store in the same table. For example, instead of having a `keys` table
with `type` set to either `Key` or `DeployKey` you'd have two separate tables:
`keys` and `deploy_keys`.

## In migrations

Whenever a model is used in a migration, single table inheritance should be disabled.
Due to the way Rails loads associations (even in migrations), failing to disable STI
could result in loading unexpected code or associations which may cause unintended
side effects or failures during upgrades.

```ruby
class SomeMigration < ActiveRecord::Migration[6.0]
  class Services < ActiveRecord::Base
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
class EnqueueSomeBackgroundMigration < ActiveRecord::Migration[6.0]
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
