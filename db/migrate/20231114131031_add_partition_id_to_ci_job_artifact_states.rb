# frozen_string_literal: true

class AddPartitionIdToCiJobArtifactStates < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  enable_lock_retries!

  def change
    add_column :ci_job_artifact_states, :partition_id, :bigint, default: 100, null: false
  end
end
