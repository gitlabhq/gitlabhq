# frozen_string_literal: true

class AddIndexOnIdCreatorIdAndCreatedAtToProjectsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_service_desk_enabled_projects_on_id_creator_id_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:id, :creator_id, :created_at], where: '"projects"."service_desk_enabled" = TRUE', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
