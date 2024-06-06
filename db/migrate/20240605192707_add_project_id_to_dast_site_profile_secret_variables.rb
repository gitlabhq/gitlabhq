# frozen_string_literal: true

class AddProjectIdToDastSiteProfileSecretVariables < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :dast_site_profile_secret_variables, :project_id, :bigint
  end
end
