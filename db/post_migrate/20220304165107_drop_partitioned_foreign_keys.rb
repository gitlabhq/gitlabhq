# frozen_string_literal: true

class DropPartitionedForeignKeys < Gitlab::Database::Migration[1.0]
  def up
    drop_table :partitioned_foreign_keys
  end

  def down
    create_table :partitioned_foreign_keys do |t|
      t.boolean :cascade_delete, null: false, default: true
      t.text :from_table, null: false, limit: 63
      t.text :from_column, null: false, limit: 63
      t.text :to_table, null: false, limit: 63
      t.text :to_column, null: false, limit: 63

      t.index [:to_table, :from_table, :from_column], unique: true, name: :index_partitioned_foreign_keys_unique_index
    end
  end
end
