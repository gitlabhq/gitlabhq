# frozen_string_literal: true

class AddWorkItemSelectFieldValuesCustomFieldSelectOptionIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_select_field_values, :custom_field_select_options,
      column: :custom_field_select_option_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_select_field_values, column: :custom_field_select_option_id
    end
  end
end
