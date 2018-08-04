# frozen_string_literal: true

class AddFailedSynchronizationsPartialIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_FAILED_INDEX_NAME = 'idx_project_registry_failed_repositories_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :project_registry,
      :repository_retry_count,
      where: "repository_retry_count > 0 OR last_repository_verification_failure IS NOT NULL OR repository_checksum_mismatch",
      name: REPOSITORY_FAILED_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:project_registry, REPOSITORY_FAILED_INDEX_NAME)
  end
end
