# frozen_string_literal: true

class DropIdxProjectsOnMirrorLastSuccessfulUpdateAt < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  TABLE_NAME = 'projects'
  INDEX_NAME = 'index_projects_on_mirror_last_successful_update_at'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :mirror_last_successful_update_at, name: INDEX_NAME
  end
end
