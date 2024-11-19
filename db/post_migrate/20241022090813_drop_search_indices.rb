# frozen_string_literal: true

class DropSearchIndices < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    drop_table :search_indices
  end

  def down
    create_table :search_indices do |t|
      t.timestamps_with_timezone null: false
      t.integer :bucket_number
      t.text :path, null: false, limit: 255
      t.text :type, null: false, limit: 255
      t.integer :number_of_shards, default: 2, null: false
      t.integer :number_of_replicas, default: 1, null: false
    end

    add_index :search_indices, [:id, :type], unique: true
    add_index :search_indices, [:type, :path], unique: true
    add_index :search_indices, [:type, :bucket_number], unique: true
  end
end
