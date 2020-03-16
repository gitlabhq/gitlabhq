# frozen_string_literal: true

class AddIndexOnIdAndServiceDeskEnabledToProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_id_service_desk_enabled'

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, :id, where: 'service_desk_enabled = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
