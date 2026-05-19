# frozen_string_literal: true

class AddEntityPrefixMappingToImportOfflineConfigurations < Gitlab::Database::Migration[2.3]
  milestone '18.12'

  def change
    add_column :import_offline_configurations, :entity_prefix_mapping, :jsonb, default: {}, null: false
  end
end
