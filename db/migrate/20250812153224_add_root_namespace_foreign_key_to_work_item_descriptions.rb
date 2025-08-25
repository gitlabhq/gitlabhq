# frozen_string_literal: true

class AddRootNamespaceForeignKeyToWorkItemDescriptions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.4'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :work_item_descriptions, :namespaces,
      column: :root_namespace_id, on_delete: :cascade, reverse_lock_order: true
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(:work_item_descriptions) do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists(
          partition.identifier,
          :work_item_descriptions,
          name: :root_namespace_id,
          reverse_lock_order: true
        )
      end
    end
  end
end
