# frozen_string_literal: true

class AddIndexesForProjectsApi < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  COLUMNS = %i(created_at last_activity_at updated_at name path)

  def up
    COLUMNS.each do |column|
      add_concurrent_index :projects, [column, :id], where: 'visibility_level = 20', order: { id: :desc }, name: "index_projects_api_vis20_#{column}_id_desc"
      add_concurrent_index :projects, [column, :id], where: 'visibility_level = 20', name: "index_projects_api_vis20_#{column}"
    end

    remove_concurrent_index_by_name :projects, 'index_projects_on_visibility_level_created_at_id_desc'
    remove_concurrent_index_by_name :projects, 'index_projects_on_visibility_level_created_at_desc_id_desc'
  end

  def down
    add_concurrent_index :projects, %i(visibility_level created_at id), order: { id: :desc }, name: 'index_projects_on_visibility_level_created_at_id_desc'
    add_concurrent_index :projects, %i(visibility_level created_at id), order: { created_at: :desc, id: :desc }, name: 'index_projects_on_visibility_level_created_at_desc_id_desc'

    COLUMNS.each do |column|
      remove_concurrent_index_by_name :projects, "index_projects_api_vis20_#{column}_id_desc"
      remove_concurrent_index_by_name :projects, "index_projects_api_vis20_#{column}"
    end
  end
end
