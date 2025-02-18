# frozen_string_literal: true

class AddWorkItemNumberFieldValues < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :work_item_number_field_values do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in ee/spec/factories/work_items/number_field_values.rb
      t.bigint :namespace_id, null: false
      t.bigint :work_item_id, null: false
      t.references :custom_field, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.numeric :value, null: false

      t.index :namespace_id
      t.index [:work_item_id, :custom_field_id], unique: true,
        name: 'idx_wi_number_values_on_work_item_id_custom_field_id'
    end
  end
end
