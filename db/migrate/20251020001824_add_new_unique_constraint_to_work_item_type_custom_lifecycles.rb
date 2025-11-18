# frozen_string_literal: true

class AddNewUniqueConstraintToWorkItemTypeCustomLifecycles < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'idx_wi_type_custom_lifecycles_on_namespace_and_work_item_type'

  def up
    add_concurrent_index :work_item_type_custom_lifecycles, [:namespace_id, :work_item_type_id],
      name: NEW_INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :work_item_type_custom_lifecycles, NEW_INDEX_NAME
  end
end
