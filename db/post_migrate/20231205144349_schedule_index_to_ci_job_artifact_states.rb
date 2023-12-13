# frozen_string_literal: true

class ScheduleIndexToCiJobArtifactStates < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME = :index_ci_job_artifact_states_on_job_artifact_id_partition_id
  TABLE_NAME = :ci_job_artifact_states
  COLUMNS = [:job_artifact_id, :partition_id]

  def up
    prepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    unprepare_async_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
