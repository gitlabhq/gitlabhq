# frozen_string_literal: true

class DropUniqueIndexJobIdFileTypeToCiJobArtifact < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!
  TABLE_NAME = :ci_job_artifacts
  INDEX_NAME = :index_ci_job_artifacts_on_job_id_and_file_type

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, %i[job_id file_type], unique: true, name: INDEX_NAME)
  end
end
