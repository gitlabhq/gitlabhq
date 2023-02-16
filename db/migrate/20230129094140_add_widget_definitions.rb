# frozen_string_literal: true

class AddWidgetDefinitions < Gitlab::Database::Migration[2.1]
  UNIQUE_INDEX_NAME = 'index_work_item_widget_definitions_on_namespace_type_and_name'
  UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME = 'index_work_item_widget_definitions_on_default_witype_and_name'

  def up
    create_table :work_item_widget_definitions do |t|
      t.references :namespace, index: false
      t.references :work_item_type, index: true, null: false
      t.integer :widget_type, null: false, limit: 2
      t.boolean :disabled, default: false
      t.text :name, limit: 255

      t.index [:namespace_id, :work_item_type_id, :name], unique: true, name: UNIQUE_INDEX_NAME
      t.index [:work_item_type_id, :name], where: "namespace_id is NULL",
        unique: true, name: UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME
    end
  end

  def down
    drop_table :work_item_widget_definitions
  end
end
