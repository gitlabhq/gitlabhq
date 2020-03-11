# frozen_string_literal: true

class AddIndexOnMirrorAndCreatorIdAndCreatedAtToProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_mirror_creator_id_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:creator_id, :created_at], where: 'mirror = true and mirror_trigger_builds = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
