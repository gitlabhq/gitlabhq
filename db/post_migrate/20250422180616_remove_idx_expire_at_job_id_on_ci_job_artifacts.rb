# frozen_string_literal: true

class RemoveIdxExpireAtJobIdOnCiJobArtifacts < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.0'

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_job_artifacts
  INDEX_COLUMNS = [:expire_at, :job_id]
  INDEX_DEFINITION = 'CREATE _ btree (expire_at, job_id)'

  # The index name ends with `1` on Production and possibly on other instances, so we must find it by definition.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/520213#note_2450943371.
  def up
    indexes_by_definition = indexes_by_definition_for_table(TABLE_NAME)
    parent_index_name = indexes_by_definition[INDEX_DEFINITION]

    if parent_index_name.nil?
      Gitlab::AppLogger.warn "Index not removed because it doesn't exist (this may be due to an aborted " \
        "migration or similar): table_name: #{TABLE_NAME}, index_definition: #{INDEX_DEFINITION}"

      return
    end

    remove_concurrent_partitioned_index_by_name TABLE_NAME, parent_index_name
  end

  def down
    parent_index_name = "#{TABLE_NAME}_#{INDEX_COLUMNS.join('_')}_idx"
    parent_index_name += '1' if index_exists_by_name?(TABLE_NAME, parent_index_name)

    add_concurrent_partitioned_index TABLE_NAME, INDEX_COLUMNS, name: parent_index_name
  end
end
