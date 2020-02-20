# frozen_string_literal: true

class DropUnneededIndexesForProjectsApiRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    indexes = %w(
      index_projects_api_vis20_created_at_id_desc
      index_projects_api_vis20_last_activity_at_id_desc
      index_projects_api_vis20_updated_at_id_desc
      index_projects_api_vis20_name_id_desc
      index_projects_api_vis20_path_id_desc
    )

    indexes.each do |index|
      remove_concurrent_index_by_name :projects, index
    end
  end

  def down
    columns = %i(created_at last_activity_at updated_at name path)

    columns.each do |column|
      add_concurrent_index :projects, [column, :id], where: 'visibility_level = 20', order: { id: :desc }, name: "index_projects_api_vis20_#{column}_id_desc"
    end
  end
end
