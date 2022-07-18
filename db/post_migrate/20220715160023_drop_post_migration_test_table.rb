# frozen_string_literal: true

class DropPostMigrationTestTable < Gitlab::Database::Migration[2.0]
  def up
    drop_table :post_migration_test_table
  end

  def down
    create_table :post_migration_test_table do |t|
      t.integer :status, null: false
    end
  end
end
