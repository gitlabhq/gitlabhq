# frozen_string_literal: true

class DropWorkItemHierarchyRestrictions < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    drop_table :work_item_hierarchy_restrictions, if_exists: true
  end

  def down
    create_table :work_item_hierarchy_restrictions do |t|
      t.bigint :parent_type_id, null: false
      t.bigint :child_type_id, null: false
      t.integer :maximum_depth, limit: 2
      t.boolean :cross_hierarchy_enabled, null: false, default: false
    end

    add_index :work_item_hierarchy_restrictions,
      [:parent_type_id, :child_type_id],
      unique: true,
      name: 'index_work_item_hierarchy_restrictions_on_parent_and_child'

    add_index :work_item_hierarchy_restrictions, :parent_type_id,
      name: 'index_work_item_hierarchy_restrictions_on_parent_type_id'

    add_index :work_item_hierarchy_restrictions, :child_type_id,
      name: 'index_work_item_hierarchy_restrictions_on_child_type_id'
  end
end
