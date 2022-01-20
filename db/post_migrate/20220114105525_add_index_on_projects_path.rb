# frozen_string_literal: true

class AddIndexOnProjectsPath < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE = :projects
  INDEX_NAME = 'index_on_projects_path'
  COLUMN = :path

  def up
    add_concurrent_index TABLE, COLUMN, name: INDEX_NAME
  end

  def down
    remove_concurrent_index TABLE, COLUMN, name: INDEX_NAME
  end
end
