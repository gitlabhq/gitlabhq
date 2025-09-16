# frozen_string_literal: true

class RemoveUniqueConstraintFromWorkItemCustomStatusMappings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    remove_concurrent_index_by_name :work_item_custom_status_mappings, 'idx_wi_status_mappings_unique_combo'
  end

  def down
    add_concurrent_index :work_item_custom_status_mappings,
      [:namespace_id, :new_status_id, :work_item_type_id, :old_status_id],
      unique: true, name: 'idx_wi_status_mappings_unique_combo'
  end
end
