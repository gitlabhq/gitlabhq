# frozen_string_literal: true

class AddIndexOnMirrorAndIdToProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'index_projects_on_mirror_and_mirror_trigger_builds_both_true'
  NEW_INDEX_NAME = 'index_projects_on_mirror_id_where_mirror_and_trigger_builds'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, :id, where: 'mirror = TRUE AND mirror_trigger_builds = TRUE', name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :projects, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :projects, :id, where: 'mirror IS TRUE AND mirror_trigger_builds IS TRUE', name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :projects, NEW_INDEX_NAME
  end
end
