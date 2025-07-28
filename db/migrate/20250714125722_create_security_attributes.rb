# frozen_string_literal: true

class CreateSecurityAttributes < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  SECURITY_ATTRIBUTES_CATEGORY_NAME_INDEX = 'index_security_attributes_security_category_name'

  def change
    create_table :security_attributes do |t|
      t.bigint :namespace_id, null: false, index: true
      t.references :security_category, foreign_key: { on_delete: :cascade }, null: false, index: false
      t.timestamps_with_timezone null: false
      t.integer :editable_state, null: false, default: 0, limit: 2
      t.text :name, null: false, limit: 255
      t.text :description, default: nil, limit: 255
      t.text :color, null: false, limit: 7

      t.index [:security_category_id, :name], unique: true, name: SECURITY_ATTRIBUTES_CATEGORY_NAME_INDEX
    end
  end
end
