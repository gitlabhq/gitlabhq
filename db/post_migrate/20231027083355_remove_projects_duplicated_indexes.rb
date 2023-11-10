# frozen_string_literal: true

class RemoveProjectsDuplicatedIndexes < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.6'

  INDEX_NAME = :index_on_projects_path
  TABLE_NAME = :projects

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :path, name: INDEX_NAME
  end
end
