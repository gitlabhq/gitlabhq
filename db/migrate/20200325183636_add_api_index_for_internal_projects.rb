# frozen_string_literal: true

class AddApiIndexForInternalProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INTERNAL_PROJECTS_INDEX_NAME = "index_projects_api_created_at_id_for_vis10"

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:created_at, :id],
      where: "visibility_level = 10 AND pending_delete = false",
      name: INTERNAL_PROJECTS_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INTERNAL_PROJECTS_INDEX_NAME
  end
end
