# frozen_string_literal: true

class ReplaceFkOnWorkItemWidgetDefinitions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  CONSTRAINT_NAME = 'fk_work_item_widget_definitions_work_item_type_id'

  def up
    add_concurrent_foreign_key :work_item_widget_definitions,
      :work_item_types,
      column: :work_item_type_id,
      on_delete: :cascade,
      on_update: :cascade,
      name: CONSTRAINT_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_widget_definitions,
        column: :work_item_type_id,
        name: CONSTRAINT_NAME
    end
  end
end
