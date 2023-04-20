# frozen_string_literal: true

class CreateSchemaInconsistencies < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :schema_inconsistencies do |t|
      t.references :issue, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :object_name, null: false, limit: 63
      t.text :table_name, null: false, limit: 63
      t.text :valitador_name, null: false, limit: 63
    end
  end
end
