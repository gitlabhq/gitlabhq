# frozen_string_literal: true

class AddLastEditedByIdForeignKeyToWorkItemDescriptions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :work_item_descriptions, :users,
      column: :last_edited_by_id, on_delete: :nullify, reverse_lock_order: true
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(:work_item_descriptions) do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists(
          partition.identifier,
          :work_item_descriptions,
          name: :last_edited_by_id,
          reverse_lock_order: true
        )
      end
    end
  end
end
