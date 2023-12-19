# frozen_string_literal: true

class DropProjectsOnCreatedAtAndIdIndex < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  TABLE_NAME = :projects
  INDEX_NAME = :index_projects_on_created_at_and_id

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, [:created_at, :id], name: INDEX_NAME
  end
end
