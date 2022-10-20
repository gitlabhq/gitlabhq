# frozen_string_literal: true

class AddScanFilePathLimitForDastSiteProfile < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :dast_site_profiles, :scan_file_path, 1024
  end

  def down
    remove_text_limit :dast_site_profiles, :scan_file_path
  end
end
