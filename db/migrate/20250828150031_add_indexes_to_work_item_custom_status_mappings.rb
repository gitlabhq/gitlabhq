# frozen_string_literal: true

class AddIndexesToWorkItemCustomStatusMappings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    # Composite for uniqueness, namespace_id queries and filtering
    add_concurrent_index :work_item_custom_status_mappings,
      [:namespace_id, :new_status_id, :work_item_type_id, :old_status_id],
      unique: true, name: 'idx_wi_status_mappings_unique_combo'

    # Indexes for FKs
    add_concurrent_index :work_item_custom_status_mappings, :old_status_id
    add_concurrent_index :work_item_custom_status_mappings, :new_status_id
    add_concurrent_index :work_item_custom_status_mappings, :work_item_type_id
    # namespace_id is covered by composite index
  end

  def down
    remove_concurrent_index_by_name :work_item_custom_status_mappings, 'idx_wi_status_mappings_unique_combo'
    remove_concurrent_index_by_name :work_item_custom_status_mappings,
      'index_work_item_custom_status_mappings_on_old_status_id'
    remove_concurrent_index_by_name :work_item_custom_status_mappings,
      'index_work_item_custom_status_mappings_on_new_status_id'
    remove_concurrent_index_by_name :work_item_custom_status_mappings,
      'index_work_item_custom_status_mappings_on_work_item_type_id'
  end
end
