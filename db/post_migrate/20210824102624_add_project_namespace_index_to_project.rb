# frozen_string_literal: true

class AddProjectNamespaceIndexToProject < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_project_namespace_id'

  def up
    add_concurrent_index :projects, :project_namespace_id, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :projects, INDEX_NAME
  end
end
