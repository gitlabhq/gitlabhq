# frozen_string_literal: true

class CreatePartitionedForeignKeys < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :partitioned_foreign_keys do |t|
      t.boolean :cascade_delete, null: false, default: true
      t.text :from_table, null: false
      t.text :from_column, null: false
      t.text :to_table, null: false
      t.text :to_column, null: false
    end

    add_text_limit :partitioned_foreign_keys, :from_table, 63
    add_text_limit :partitioned_foreign_keys, :from_column, 63
    add_text_limit :partitioned_foreign_keys, :to_table, 63
    add_text_limit :partitioned_foreign_keys, :to_column, 63

    add_index :partitioned_foreign_keys, [:to_table, :from_table, :from_column], unique: true,
      name: "index_partitioned_foreign_keys_unique_index"
  end

  def down
    drop_table :partitioned_foreign_keys
  end
end
