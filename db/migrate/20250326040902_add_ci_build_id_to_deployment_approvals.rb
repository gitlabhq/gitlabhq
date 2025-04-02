# frozen_string_literal: true

class AddCiBuildIdToDeploymentApprovals < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :deployment_approvals, :ci_build_id, :bigint
  end
end
