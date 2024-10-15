# frozen_string_literal: true

class CreateCustomFieldSelectOptions < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :custom_field_select_options do |t|
      t.references :namespace, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.bigint :custom_field_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :position, null: false, limit: 2
      t.text :value, null: false, limit: 255

      t.index 'custom_field_id, LOWER(value)',
        name: 'idx_custom_field_select_options_on_custom_field_id_lower_value', unique: true
    end
  end
end
