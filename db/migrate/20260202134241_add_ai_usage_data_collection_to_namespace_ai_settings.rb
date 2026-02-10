# frozen_string_literal: true

class AddAiUsageDataCollectionToNamespaceAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    add_column :namespace_ai_settings, :ai_usage_data_collection_enabled, :boolean, default: false, null: false
  end

  def down
    remove_column :namespace_ai_settings, :ai_usage_data_collection_enabled
  end
end
