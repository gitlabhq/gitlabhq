# frozen_string_literal: true

class AddNamespaceIndexToWorkItemCustomStatusMappings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_index :work_item_custom_status_mappings, :namespace_id
  end

  def down
    remove_concurrent_index_by_name :work_item_custom_status_mappings,
      'index_work_item_custom_status_mappings_on_namespace_id'
  end
end
