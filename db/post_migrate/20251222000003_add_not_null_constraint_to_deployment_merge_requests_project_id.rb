# frozen_string_literal: true

class AddNotNullConstraintToDeploymentMergeRequestsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :deployment_merge_requests, :project_id
  end

  def down
    remove_not_null_constraint :deployment_merge_requests, :project_id
  end
end
