# frozen_string_literal: true

class AddOptionsToAiActiveContextCollections < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    add_column :ai_active_context_collections, :options, :jsonb, null: false, default: {}
  end

  def down
    remove_column :ai_active_context_collections, :options
  end
end
