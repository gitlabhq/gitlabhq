# frozen_string_literal: true

class AddIndexesForProjectsApiDefaultParamsAuthenticated < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, %i(created_at id)
    remove_concurrent_index_by_name :projects, 'index_projects_on_created_at'
  end

  def down
    add_concurrent_index :projects, :created_at
    remove_concurrent_index_by_name :projects, 'index_projects_on_created_at_and_id'
  end
end
