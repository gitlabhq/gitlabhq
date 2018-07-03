class FillFileLocationToJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  TMP_INDEX = 'tmp_index_ci_job_artifacts_on_id_with_null_file_location'.freeze
  CI_JOB_ARTIFACT_FILE_LOCATION_HASHED_PATH = 2 # Equavalant to Ci::JobArtifact.file_locations[:hashed_path]

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_job_artifacts'
  end

  def up
    unless index_exists_by_name?(:ci_job_artifacts, TMP_INDEX)
      # This partial index is to be removed after the clean-up phase of the background migrations for legacy artifacts.
      add_concurrent_index(:ci_job_artifacts, :id, where: 'file_location is NULL', name: TMP_INDEX)
    end

    # TODO: Use background migrations?
    FillFileLocationToJobArtifacts::JobArtifact.where(file_location: nil).each_batch(of: BATCH_SIZE) do |relation|
      relation.update_all(file_location: CI_JOB_ARTIFACT_FILE_LOCATION_HASHED_PATH)
    end
  end

  def down
    if index_exists_by_name?(:ci_job_artifacts, TMP_INDEX)
      remove_concurrent_index_by_name(:ci_job_artifacts, TMP_INDEX)
    end
  end
end
