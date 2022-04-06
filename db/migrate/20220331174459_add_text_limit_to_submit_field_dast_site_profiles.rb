# frozen_string_literal: true

class AddTextLimitToSubmitFieldDastSiteProfiles < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :dast_site_profiles, :auth_submit_field, 255
  end

  def down
    remove_text_limit :dast_site_profiles, :auth_submit_field
  end
end
