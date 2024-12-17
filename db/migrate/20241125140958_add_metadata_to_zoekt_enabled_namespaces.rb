# frozen_string_literal: true

class AddMetadataToZoektEnabledNamespaces < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :zoekt_enabled_namespaces, :metadata, :jsonb, default: {}, null: false
  end
end
