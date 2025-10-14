# frozen_string_literal: true

class AddShardingKeyToSuggestions < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :suggestions, :namespace_id, :bigint
  end
end
