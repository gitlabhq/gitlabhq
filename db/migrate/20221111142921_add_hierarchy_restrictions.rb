# frozen_string_literal: true

class AddHierarchyRestrictions < Gitlab::Database::Migration[2.0]
  UNIQUE_INDEX_NAME = 'index_work_item_hierarchy_restrictions_on_parent_and_child'

  def up
    create_table :work_item_hierarchy_restrictions do |t|
      t.references :parent_type, index: true, null: false,
                                 foreign_key: { on_delete: :cascade, to_table: :work_item_types }
      t.references :child_type, index: true, null: false,
                                foreign_key: { on_delete: :cascade, to_table: :work_item_types }
      t.integer :maximum_depth, limit: 2

      t.index [:parent_type_id, :child_type_id], unique: true, name: UNIQUE_INDEX_NAME
    end
  end

  def down
    drop_table :work_item_hierarchy_restrictions
  end
end
