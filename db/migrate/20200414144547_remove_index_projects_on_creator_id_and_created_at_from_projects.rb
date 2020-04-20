# frozen_string_literal: true

class RemoveIndexProjectsOnCreatorIdAndCreatedAtFromProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_creator_id_and_created_at'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end

  def down
    add_concurrent_index :projects, [:creator_id, :created_at], name: INDEX_NAME
  end
end
