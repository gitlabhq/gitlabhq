# frozen_string_literal: true

class DropArtifactsPartitionIdJobIdIndex < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  INDEX_NAME = :p_ci_job_artifacts_partition_id_job_id_idx
  COLUMNS = [:partition_id, :job_id]

  # Index to be destroyed synchronously in
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187564
  #
  def up
    prepare_async_index_removal :p_ci_job_artifacts, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :p_ci_job_artifacts, COLUMNS, name: INDEX_NAME
  end
end
