# frozen_string_literal: true

class AddMergeRequestsIndexOnTargetProjectAndBranch < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, [:target_project_id, :target_branch],
      where: "state_id = 1 AND merge_when_pipeline_succeeds = true"
  end

  def down
    remove_concurrent_index :merge_requests, [:target_project_id, :target_branch]
  end
end
