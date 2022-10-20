# frozen_string_literal: true

class AddScanFilePathToDastSiteProfile < Gitlab::Database::Migration[2.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20221012135524_add_scan_file_path_limit_for_dast_site_profile
  def up
    add_column :dast_site_profiles, :scan_file_path, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :dast_site_profiles, :scan_file_path, :text
  end
end
