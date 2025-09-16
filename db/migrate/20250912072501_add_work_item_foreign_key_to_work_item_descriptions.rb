# frozen_string_literal: true

class AddWorkItemForeignKeyToWorkItemDescriptions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :work_item_descriptions, :issues, column: :work_item_id,
      on_delete: :cascade, reverse_lock_order: true
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(:work_item_descriptions) do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists(
          partition.identifier,
          :work_item_descriptions,
          name: :work_item_id,
          reverse_lock_order: true
        )
      end
    end
  end
end
