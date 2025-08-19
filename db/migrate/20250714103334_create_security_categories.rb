# frozen_string_literal: true

class CreateSecurityCategories < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  SECURITY_CATEGORIES_NAME_NAMESPACE_INDEX = 'index_security_categories_namespace_name'

  def change
    create_table :security_categories do |t|
      t.bigint :namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :editable_state, null: false, default: 0, limit: 2
      t.integer :template_type, null: true, limit: 2
      t.boolean :multiple_selection, null: false, default: false
      t.text :name, null: false, limit: 255
      t.text :description, default: nil, limit: 255

      t.index [:namespace_id, :name], unique: true, name: SECURITY_CATEGORIES_NAME_NAMESPACE_INDEX
    end
  end
end
