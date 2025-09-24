# frozen_string_literal: true

class RemoveFkReferencesToWorkItemTypeOnHierarchyRestrictions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_hierarchy_restrictions,
        name: "fk_work_item_hierarchy_restrictions_child_type_id"
      remove_foreign_key_if_exists :work_item_hierarchy_restrictions,
        name: "fk_work_item_hierarchy_restrictions_parent_type_id"
    end
  end

  def down
    add_concurrent_foreign_key :work_item_hierarchy_restrictions, :work_item_types, column: :parent_type_id,
      name: "fk_work_item_hierarchy_restrictions_parent_type_id", on_update: :cascade, on_delete: :cascade
    add_concurrent_foreign_key :work_item_hierarchy_restrictions, :work_item_types, column: :child_type_id,
      name: "fk_work_item_hierarchy_restrictions_child_type_id", on_update: :cascade, on_delete: :cascade
  end
end
