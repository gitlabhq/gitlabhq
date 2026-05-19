# frozen_string_literal: true

class DropWorkItemWidgetDefinitions < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  TABLE_NAME = :work_item_widget_definitions

  def up
    drop_table TABLE_NAME, if_exists: true
  end

  def down
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.bigint :work_item_type_id, null: false
      t.integer :widget_type, null: false, limit: 2
      t.boolean :disabled, default: false
      t.text :name
      t.jsonb :widget_options

      t.check_constraint 'char_length(name) <= 255', name: 'check_050f2e2328'
    end

    add_concurrent_index TABLE_NAME, :work_item_type_id,
      name: 'index_work_item_widget_definitions_on_work_item_type_id'

    add_concurrent_index TABLE_NAME,
      'work_item_type_id, TRIM(BOTH FROM lower(name))',
      unique: true,
      name: 'index_work_item_widget_definitions_on_type_id_and_name'
  end
end
