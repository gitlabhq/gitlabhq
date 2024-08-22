# frozen_string_literal: true

class AddWorkItemWidgetDefinitionsNameUniqueIndex < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_work_item_widget_definitions_on_type_id_and_name'

  disable_ddl_transaction!

  milestone '17.4'

  def up
    add_concurrent_index :work_item_widget_definitions,
      'work_item_type_id, TRIM(BOTH FROM LOWER(name))',
      name: INDEX_NAME,
      unique: true
  end

  def down
    remove_concurrent_index_by_name :work_item_widget_definitions, INDEX_NAME
  end
end
