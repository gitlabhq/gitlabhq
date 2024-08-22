# frozen_string_literal: true

class DropWorkItemWidgetDefinitionsNamespaceId < Gitlab::Database::Migration[2.2]
  UNIQUE_INDEX_NAME = 'index_work_item_widget_definitions_on_namespace_type_and_name'
  UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME = 'index_work_item_widget_definitions_on_default_witype_and_name'

  disable_ddl_transaction!

  milestone '17.4'

  def up
    remove_column :work_item_widget_definitions, :namespace_id
  end

  def down
    add_column :work_item_widget_definitions, :namespace_id, :bigint

    add_concurrent_index :work_item_widget_definitions,
      [:namespace_id, :work_item_type_id, :name],
      unique: true,
      name: UNIQUE_INDEX_NAME

    add_concurrent_index :work_item_widget_definitions,
      [:work_item_type_id, :name],
      where: "namespace_id is NULL",
      unique: true,
      name: UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME

    add_concurrent_foreign_key :work_item_widget_definitions, :namespaces, column: :namespace_id, on_delete: :cascade
  end
end
