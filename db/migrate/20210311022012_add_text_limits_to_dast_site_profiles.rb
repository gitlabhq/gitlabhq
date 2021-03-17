# frozen_string_literal: true

class AddTextLimitsToDastSiteProfiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :dast_site_profiles, :auth_url, 1024
    add_text_limit :dast_site_profiles, :auth_username_field, 255
    add_text_limit :dast_site_profiles, :auth_password_field, 255
    add_text_limit :dast_site_profiles, :auth_username, 255
  end

  def down
    remove_text_limit :dast_site_profiles, :auth_username
    remove_text_limit :dast_site_profiles, :auth_password_field
    remove_text_limit :dast_site_profiles, :auth_username_field
    remove_text_limit :dast_site_profiles, :auth_url
  end
end
