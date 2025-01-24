# frozen_string_literal: true

class AddWorkItemSelectFieldValues < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :work_item_select_field_values do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in ee/spec/factories/work_items/select_field_values.rb
      t.bigint :namespace_id, null: false
      t.bigint :work_item_id, null: false
      t.references :custom_field, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.bigint :custom_field_select_option_id, null: false
      t.timestamps_with_timezone null: false

      t.index :namespace_id
      t.index [:work_item_id, :custom_field_id, :custom_field_select_option_id], unique: true,
        name: 'idx_wi_select_values_on_wi_custom_field_id_select_option_id'
      t.index :custom_field_select_option_id, name: 'idx_wi_select_field_values_on_custom_field_select_option_id'
    end
  end
end
