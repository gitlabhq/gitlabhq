# frozen_string_literal: true

class AddIndexOnProjectIdAndTypeToServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_services_on_project_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :services, [:project_id, :type]

    remove_concurrent_index_by_name :services, INDEX_NAME
  end

  def down
    add_concurrent_index :services, :project_id, name: INDEX_NAME

    remove_concurrent_index :services, [:project_id, :type]
  end
end
