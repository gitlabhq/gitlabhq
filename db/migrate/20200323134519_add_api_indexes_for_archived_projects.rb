# frozen_string_literal: true

class AddApiIndexesForArchivedProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  PUBLIC_AND_ARCHIVED_INDEX_NAME = "index_projects_api_created_at_id_for_archived_vis20"
  ARCHIVED_INDEX_NAME = "index_projects_api_created_at_id_for_archived"

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:created_at, :id],
      where: "archived = true AND visibility_level = 20 AND pending_delete = false",
      name: PUBLIC_AND_ARCHIVED_INDEX_NAME

    add_concurrent_index :projects, [:created_at, :id], where: "archived = true AND pending_delete = false",
      name: ARCHIVED_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, ARCHIVED_INDEX_NAME

    remove_concurrent_index_by_name :projects, PUBLIC_AND_ARCHIVED_INDEX_NAME
  end
end
