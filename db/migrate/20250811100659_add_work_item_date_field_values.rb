# frozen_string_literal: true

class AddWorkItemDateFieldValues < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    create_table :work_item_date_field_values do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is in ee/spec/factories/work_items/date_field_values.rb
      t.bigint :namespace_id, null: false
      t.bigint :work_item_id, null: false
      t.references :custom_field, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.date :value, null: false

      t.index :namespace_id
      t.index [:work_item_id, :custom_field_id], unique: true,
        name: 'i_wi_date_values_on_work_item_id_custom_field_id'
    end
  end
end
