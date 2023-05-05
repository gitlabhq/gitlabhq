# frozen_string_literal: true

class AddScanMethodToDastSiteProfile < Gitlab::Database::Migration[1.0]
  def up
    add_column :dast_site_profiles, :scan_method, :integer, limit: 2, default: 0, null: false
  end

  def down
    remove_column :dast_site_profiles, :scan_method
  end
end
