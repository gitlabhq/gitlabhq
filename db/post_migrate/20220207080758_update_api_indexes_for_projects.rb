# frozen_string_literal: true

class UpdateApiIndexesForProjects < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  ARCHIVED_INDEX_NAME = 'idx_projects_api_created_at_id_for_archived'
  OLD_ARCHIVED_INDEX_NAME = 'index_projects_api_created_at_id_for_archived'
  PUBLIC_AND_ARCHIVED_INDEX_NAME = 'idx_projects_api_created_at_id_for_archived_vis20'
  OLD_PUBLIC_AND_ARCHIVED_INDEX_NAME = 'index_projects_api_created_at_id_for_archived_vis20'
  INTERNAL_PROJECTS_INDEX_NAME = 'idx_projects_api_created_at_id_for_vis10'
  OLD_INTERNAL_PROJECTS_INDEX_NAME = 'index_projects_api_created_at_id_for_vis10'

  def up
    add_concurrent_index :projects, [:created_at, :id],
                         where: "archived = true AND pending_delete = false AND hidden = false",
                         name: ARCHIVED_INDEX_NAME

    add_concurrent_index :projects, [:created_at, :id],
                         where: "archived = true AND visibility_level = 20 AND pending_delete = false AND hidden = false",
                         name: PUBLIC_AND_ARCHIVED_INDEX_NAME

    add_concurrent_index :projects, [:created_at, :id],
                         where: "visibility_level = 10 AND pending_delete = false AND hidden = false",
                         name: INTERNAL_PROJECTS_INDEX_NAME

    remove_concurrent_index_by_name :projects, OLD_ARCHIVED_INDEX_NAME
    remove_concurrent_index_by_name :projects, OLD_PUBLIC_AND_ARCHIVED_INDEX_NAME
    remove_concurrent_index_by_name :projects, OLD_INTERNAL_PROJECTS_INDEX_NAME
  end

  def down
    add_concurrent_index :projects, [:created_at, :id],
                         where: "archived = true AND pending_delete = false",
                         name: OLD_ARCHIVED_INDEX_NAME

    add_concurrent_index :projects, [:created_at, :id],
                         where: "archived = true AND visibility_level = 20 AND pending_delete = false",
                         name: OLD_PUBLIC_AND_ARCHIVED_INDEX_NAME

    add_concurrent_index :projects, [:created_at, :id],
                         where: "visibility_level = 10 AND pending_delete = false",
                         name: OLD_INTERNAL_PROJECTS_INDEX_NAME

    remove_concurrent_index_by_name :projects, ARCHIVED_INDEX_NAME
    remove_concurrent_index_by_name :projects, PUBLIC_AND_ARCHIVED_INDEX_NAME
    remove_concurrent_index_by_name :projects, INTERNAL_PROJECTS_INDEX_NAME
  end
end
