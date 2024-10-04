# frozen_string_literal: true

class CreateCustomFields < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :custom_fields do |t|
      t.references :namespace, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :archived_at
      t.integer :field_type, null: false, limit: 2
      t.text :name, null: false, limit: 255

      t.index 'namespace_id, LOWER(name)',
        name: 'idx_custom_fields_on_namespace_id_and_lower_name', unique: true
    end
  end
end
