# frozen_string_literal: true

class DropIndexOnProjectsLowerPath < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = :projects
  INDEX_NAME = :index_on_projects_lower_path

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, "(lower((path)::text))", name: INDEX_NAME
  end
end
