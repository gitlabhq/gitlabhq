# frozen_string_literal: true

class RemoveWorkItemDescriptionsNamespaceIdFk < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.2'

  CONSTRAINT_NAME = 'fk_rails_31c499d2ce'

  def up
    remove_partitioned_foreign_key :work_item_descriptions, :namespaces,
      column: :namespace_id, name: CONSTRAINT_NAME, reverse_lock_order: true
  end

  def down
    add_concurrent_partitioned_foreign_key :work_item_descriptions, :namespaces,
      column: :namespace_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
