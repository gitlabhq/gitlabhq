class AddPartialIndexToProjectsForIndexOnlyScans < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_id_partial_for_visibility'

  disable_ddl_transaction!

  # Adds a partial index to leverage index-only scans when looking up project ids
  def up
    unless index_exists?(:projects, :id, name: INDEX_NAME)
      add_concurrent_index :projects, :id, name: INDEX_NAME, unique: true, where: 'visibility_level IN (10,20)'
    end
  end

  def down
    if index_exists?(:projects, :id, name: INDEX_NAME)
      remove_concurrent_index_by_name :projects, INDEX_NAME
    end
  end
end
