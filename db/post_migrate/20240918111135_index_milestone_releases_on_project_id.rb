# frozen_string_literal: true

class IndexMilestoneReleasesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_milestone_releases_on_project_id'

  def up
    add_concurrent_index :milestone_releases, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :milestone_releases, INDEX_NAME
  end
end
