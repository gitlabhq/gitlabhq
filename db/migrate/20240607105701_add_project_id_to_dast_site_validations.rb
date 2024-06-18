# frozen_string_literal: true

class AddProjectIdToDastSiteValidations < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :dast_site_validations, :project_id, :bigint
  end
end
