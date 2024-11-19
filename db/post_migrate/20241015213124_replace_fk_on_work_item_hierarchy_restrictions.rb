# frozen_string_literal: true

class ReplaceFkOnWorkItemHierarchyRestrictions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  CHILD_CONSTRAINT_NAME = 'fk_work_item_hierarchy_restrictions_child_type_id'
  PARENT_CONSTRAINT_NAME = 'fk_work_item_hierarchy_restrictions_parent_type_id'

  def up
    add_concurrent_foreign_key :work_item_hierarchy_restrictions,
      :work_item_types,
      column: :child_type_id,
      on_delete: :cascade,
      on_update: :cascade,
      name: CHILD_CONSTRAINT_NAME

    add_concurrent_foreign_key :work_item_hierarchy_restrictions,
      :work_item_types,
      column: :parent_type_id,
      on_delete: :cascade,
      on_update: :cascade,
      name: PARENT_CONSTRAINT_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_hierarchy_restrictions,
        column: :child_type_id,
        name: CHILD_CONSTRAINT_NAME
      remove_foreign_key_if_exists :work_item_hierarchy_restrictions,
        column: :parent_type_id,
        name: PARENT_CONSTRAINT_NAME
    end
  end
end
