# frozen_string_literal: true

class AddProjectIdToDastSiteProfilesBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :dast_site_profiles_builds, :project_id, :bigint
  end
end
