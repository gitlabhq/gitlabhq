# frozen_string_literal: true

class AddChecksumMismatchSelfHealSettingsToGeoNodes < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :geo_nodes, :checksum_mismatch_report_threshold, :integer, default: 3, null: false,
      if_not_exists: true
    add_column :geo_nodes, :checksum_mismatch_self_heal_cooldown_minutes, :integer, default: 60, null: false,
      if_not_exists: true
  end
end
