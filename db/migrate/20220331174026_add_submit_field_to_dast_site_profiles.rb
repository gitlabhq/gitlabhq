# frozen_string_literal: true

class AddSubmitFieldToDastSiteProfiles < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220331174459_add_text_limit_to_submit_field_dast_site_profiles
  def change
    add_column :dast_site_profiles, :auth_submit_field, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
