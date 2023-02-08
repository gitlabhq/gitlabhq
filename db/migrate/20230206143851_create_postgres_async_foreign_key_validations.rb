# frozen_string_literal: true

class CreatePostgresAsyncForeignKeyValidations < Gitlab::Database::Migration[2.1]
  def change
    create_table :postgres_async_foreign_key_validations, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.text :name, null: false, limit: 63
      t.text :table_name, null: false, limit: 63
      t.text :last_error, limit: 10_000

      t.integer :attempts, null: false, default: 0

      t.index :name, unique: true
    end
  end
end
