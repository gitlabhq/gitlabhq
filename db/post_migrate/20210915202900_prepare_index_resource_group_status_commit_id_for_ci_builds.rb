# frozen_string_literal: true

class PrepareIndexResourceGroupStatusCommitIdForCiBuilds < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_ci_builds_on_resource_group_and_status_and_commit_id'

  def up
    prepare_async_index :ci_builds, [:resource_group_id, :status, :commit_id],
      where: 'resource_group_id IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :ci_builds, INDEX_NAME
  end
end
