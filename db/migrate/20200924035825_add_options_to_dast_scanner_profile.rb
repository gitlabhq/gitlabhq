# frozen_string_literal: true

class AddOptionsToDastScannerProfile < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  PASSIVE_SCAN_ENUM_VALUE = 1

  def change
    add_column :dast_scanner_profiles, :scan_type, :integer, limit: 2, default: PASSIVE_SCAN_ENUM_VALUE, null: false
    add_column :dast_scanner_profiles, :use_ajax_spider, :boolean, default: false, null: false
    add_column :dast_scanner_profiles, :show_debug_messages, :boolean, default: false, null: false
  end
end
