# frozen_string_literal: true

class AddProjectIdToTerraformStateVersions < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :terraform_state_versions, :project_id, :bigint
  end
end
