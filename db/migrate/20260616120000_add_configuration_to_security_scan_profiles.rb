# frozen_string_literal: true

class AddConfigurationToSecurityScanProfiles < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :security_scan_profiles, :configuration, :jsonb, default: {}, null: false
  end
end
