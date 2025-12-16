# frozen_string_literal: true

class CreateSavedViews < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    create_table :saved_views do |t|
      t.timestamps_with_timezone null: false
      t.references :namespace, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.bigint :created_by_id, index: true
      t.integer :version, null: false
      t.boolean :private, null: false, index: true, default: true
      t.text :name, null: false, limit: 140
      t.text :description, limit: 140
      t.integer :sort, limit: 2
      t.jsonb :filter_data
      t.jsonb :display_settings

      t.index [:namespace_id, :name], unique: true
      t.index [:namespace_id, :private, :created_by_id], name: 'index_saved_views_on_namespace_private_created_by'
    end
  end
end
