# frozen_string_literal: true

class CreateSearchIndices < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :search_indices do |t|
      t.timestamps_with_timezone null: false
      t.integer :bucket_number # We allow null bucket numbers to support custom index assignments
      t.text :path, null: false, limit: 255
      t.text :type, null: false, limit: 255
    end

    add_index :search_indices, [:id, :type], unique: true
    add_index :search_indices, [:type, :path], unique: true
    add_index :search_indices, [:type, :bucket_number], unique: true
  end
end
