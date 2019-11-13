# frozen_string_literal: true

class AddIndexesForProjectsApiDefaultParams < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, %i(visibility_level created_at id)
    remove_concurrent_index_by_name :projects, 'index_projects_on_visibility_level'
  end

  def down
    add_concurrent_index :projects, :visibility_level
    remove_concurrent_index :projects, %i(visibility_level created_at id)
  end
end
