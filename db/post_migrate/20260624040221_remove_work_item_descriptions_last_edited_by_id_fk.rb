# frozen_string_literal: true

class RemoveWorkItemDescriptionsLastEditedByIdFk < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.2'

  CONSTRAINT_NAME = 'fk_rails_600bd0d333'

  def up
    remove_partitioned_foreign_key :work_item_descriptions, :users,
      column: :last_edited_by_id, name: CONSTRAINT_NAME, reverse_lock_order: true
  end

  def down
    add_concurrent_partitioned_foreign_key :work_item_descriptions, :users,
      column: :last_edited_by_id, on_delete: :nullify, name: CONSTRAINT_NAME
  end
end
