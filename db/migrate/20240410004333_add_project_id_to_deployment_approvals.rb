# frozen_string_literal: true

class AddProjectIdToDeploymentApprovals < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :deployment_approvals, :project_id, :bigint
  end
end
