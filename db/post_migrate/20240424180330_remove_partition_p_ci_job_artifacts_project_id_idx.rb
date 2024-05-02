# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemovePartitionPCiJobArtifactsProjectIdIdx < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.0'

  INDEX_NAME = :p_ci_job_artifacts_project_id_idx
  TABLE_NAME = :p_ci_job_artifacts

  def up
    unprepare_async_index_by_name(TABLE_NAME, INDEX_NAME)
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end
end
