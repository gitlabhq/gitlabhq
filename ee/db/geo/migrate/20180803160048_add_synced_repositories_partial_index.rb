# frozen_string_literal: true

class AddSyncedRepositoriesPartialIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_SYNCED_INDEX_NAME = 'idx_project_registry_synced_repositories_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :project_registry,
      :last_repository_successful_sync_at,
      where: "resync_repository = 'f' AND repository_retry_count IS NULL AND repository_verification_checksum_sha IS NOT NULL",
      name: REPOSITORY_SYNCED_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:project_registry, REPOSITORY_SYNCED_INDEX_NAME)
  end
end
