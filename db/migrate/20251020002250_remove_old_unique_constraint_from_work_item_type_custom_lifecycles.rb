# frozen_string_literal: true

class RemoveOldUniqueConstraintFromWorkItemTypeCustomLifecycles < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'idx_wi_type_custom_lifecycles_on_namespace_type_lifecycle'

  def up
    remove_concurrent_index_by_name :work_item_type_custom_lifecycles, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :work_item_type_custom_lifecycles, [:namespace_id, :work_item_type_id, :lifecycle_id],
      name: OLD_INDEX_NAME, unique: true
  end
end
