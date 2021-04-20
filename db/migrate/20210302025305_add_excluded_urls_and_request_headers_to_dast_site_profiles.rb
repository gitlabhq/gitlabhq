# frozen_string_literal: true

class AddExcludedUrlsAndRequestHeadersToDastSiteProfiles < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210311022012_add_text_limits_to_dast_site_profiles
  def change
    add_column :dast_site_profiles, :excluded_urls, :text, array: true, default: [], null: false
    add_column :dast_site_profiles, :auth_enabled, :boolean, default: false, null: false
    add_column :dast_site_profiles, :auth_url, :text
    add_column :dast_site_profiles, :auth_username_field, :text
    add_column :dast_site_profiles, :auth_password_field, :text
    add_column :dast_site_profiles, :auth_username, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
