# frozen_string_literal: true

class AsyncRemoveIdxExpireAtJobIdOnCiJobArtifacts < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.0'

  TABLE_NAME = :p_ci_job_artifacts
  INDEX_DEFINITION = 'CREATE _ btree (expire_at, job_id)'
  COLUMNS = [:expire_at, :job_id]

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/532779
  def up
    return unless index_name

    prepare_async_index_removal TABLE_NAME, COLUMNS, name: index_name
  end

  def down
    return unless index_name

    unprepare_async_index TABLE_NAME, COLUMNS, name: index_name
  end

  private

  # This index has a different name on Production DB and possibly on other instances.
  # So we must find the index by definition instead.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/520213#note_2450943371.
  def index_name
    indexes_by_definition = indexes_by_definition_for_table(TABLE_NAME)
    indexes_by_definition[INDEX_DEFINITION]
  end
end
