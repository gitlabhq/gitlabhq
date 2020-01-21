# frozen_string_literal: true

class AddIndexesForProjectsApiAuthenticated < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  COLUMNS = %i(updated_at name)

  def up
    add_concurrent_index :projects, %i(created_at id), order: { id: :desc }, name: 'index_projects_api_created_at_id_desc'

    add_concurrent_index :projects, %i(last_activity_at id), name: 'index_projects_on_last_activity_at_and_id'
    remove_concurrent_index :projects, :last_activity_at
    add_concurrent_index :projects, %i(last_activity_at id), order: { id: :desc }, name: 'index_projects_api_last_activity_at_id_desc'

    add_concurrent_index :projects, %i(path id), name: 'index_projects_on_path_and_id'
    remove_concurrent_index_by_name :projects, 'index_projects_on_path'
    add_concurrent_index :projects, %i(path id), order: { id: :desc }, name: 'index_projects_api_path_id_desc'

    COLUMNS.each do |column|
      add_concurrent_index :projects, [column, :id], name: "index_projects_on_#{column}_and_id"
      add_concurrent_index :projects, [column, :id], order: { id: :desc }, name: "index_projects_api_#{column}_id_desc"
    end
  end

  def down
    remove_concurrent_index_by_name :projects, 'index_projects_api_created_at_id_desc'

    remove_concurrent_index_by_name :projects, 'index_projects_on_last_activity_at_and_id'
    add_concurrent_index :projects, :last_activity_at, name: 'index_projects_on_last_activity_at'
    remove_concurrent_index_by_name :projects, 'index_projects_api_last_activity_at_id_desc'

    remove_concurrent_index_by_name :projects, 'index_projects_on_path_and_id'
    add_concurrent_index :projects, :path, name: 'index_projects_on_path'
    remove_concurrent_index_by_name :projects, 'index_projects_api_path_id_desc'

    COLUMNS.each do |column|
      remove_concurrent_index_by_name :projects, "index_projects_on_#{column}_and_id"
      remove_concurrent_index_by_name :projects, "index_projects_api_#{column}_id_desc"
    end
  end
end
