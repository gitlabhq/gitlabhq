# frozen_string_literal: true

class AddForeignKeysToWorkItemCustomStatusMappings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    # When namespace is removed, we don't need the mappings.
    add_concurrent_foreign_key :work_item_custom_status_mappings, :namespaces,
      column: :namespace_id, on_delete: :cascade, name: 'fk_wi_status_mappings_namespace_id'

    # Use restrict here because we want to prevent deletion of custom statuses
    # that are used in mappings as old_status_id.
    # It's okay to delete a mapping when there're no work items that have the old status,
    # but we should handle that in application logic.
    add_concurrent_foreign_key :work_item_custom_status_mappings, :work_item_custom_statuses,
      column: :old_status_id, on_delete: :restrict, name: 'fk_wi_status_mappings_old_status_id'

    # Removing the replacement status should be fine from a data integrity standpoint because
    # we only resolve the status of the work item to the new status, it's not
    # set as the status of the work item.
    add_concurrent_foreign_key :work_item_custom_status_mappings, :work_item_custom_statuses,
      column: :new_status_id, on_delete: :cascade, name: 'fk_wi_status_mappings_new_status_id'

    # When work items are removed, we don't need the mappings for them.
    add_concurrent_foreign_key :work_item_custom_status_mappings, :work_item_types,
      column: :work_item_type_id, on_delete: :cascade, name: 'fk_wi_status_mappings_work_item_type_id'
  end

  def down
    remove_foreign_key :work_item_custom_status_mappings, name: 'fk_wi_status_mappings_namespace_id'
    remove_foreign_key :work_item_custom_status_mappings, name: 'fk_wi_status_mappings_old_status_id'
    remove_foreign_key :work_item_custom_status_mappings, name: 'fk_wi_status_mappings_new_status_id'
    remove_foreign_key :work_item_custom_status_mappings, name: 'fk_wi_status_mappings_work_item_type_id'
  end
end
