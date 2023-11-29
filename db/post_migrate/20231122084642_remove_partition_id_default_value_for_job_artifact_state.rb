# frozen_string_literal: true

class RemovePartitionIdDefaultValueForJobArtifactState < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def up
    change_column_default :ci_job_artifact_states, :partition_id, from: 100, to: nil
  end

  def down
    change_column_default :ci_job_artifact_states, :partition_id, from: nil, to: 100
  end
end
