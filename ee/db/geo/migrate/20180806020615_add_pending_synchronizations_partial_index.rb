# frozen_string_literal: true

class AddPendingSynchronizationsPartialIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_PENDING_INDEX_NAME = 'idx_project_registry_pending_repositories_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :project_registry,
      :repository_retry_count,
      where: "repository_retry_count IS NULL AND last_repository_successful_sync_at IS NOT NULL AND (resync_repository = 't' OR repository_verification_checksum_sha IS NULL AND last_repository_verification_failure IS NULL)",
      name: REPOSITORY_PENDING_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:project_registry, REPOSITORY_PENDING_INDEX_NAME)
  end
end
