# frozen_string_literal: true

class AddShardSettingsToSearchIndices < Gitlab::Database::Migration[2.1]
  def change
    add_column :search_indices, :number_of_shards, :integer, default: 2, null: false
    add_column :search_indices, :number_of_replicas, :integer, default: 1, null: false
  end
end
