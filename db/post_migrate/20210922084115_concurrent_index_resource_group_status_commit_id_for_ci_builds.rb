# frozen_string_literal: true

class ConcurrentIndexResourceGroupStatusCommitIdForCiBuilds < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_ci_builds_on_resource_group_and_status_and_commit_id'

  disable_ddl_transaction!

  # Indexes were pre-created on gitlab.com to avoid slowing down deployments
  # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70279

  # rubocop: disable Migration/PreventIndexCreation
  def up
    add_concurrent_index :ci_builds, [:resource_group_id, :status, :commit_id],
      where: 'resource_group_id IS NOT NULL',
      name: INDEX_NAME
  end
  # rubocop: enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end
end
