# frozen_string_literal: true

class CreateImportSourceUserPlaceholderReference < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  enable_lock_retries!

  INDEX_NAME = 'index_import_source_user_placeholder_references_on_source_user_'

  def change
    create_table :import_source_user_placeholder_references do |t|
      t.references :source_user,
        index: { name: INDEX_NAME },
        null: false,
        foreign_key: { to_table: :import_source_users, on_delete: :cascade }
      t.references :namespace, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.bigint :numeric_key, null: true
      t.datetime_with_timezone :created_at, null: false
      t.text :model, limit: 150, null: false
      t.text :user_reference_column, limit: 50, null: false
      t.jsonb :composite_key, null: true
    end
  end
end
