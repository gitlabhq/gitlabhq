# frozen_string_literal: true

class RemoveUniqueIndexForSprintsOnProjectIdAndTitle < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_sprints_on_project_id_and_title'

  def up
    remove_concurrent_index_by_name :sprints, INDEX_NAME
  end

  def down
    add_concurrent_index :sprints, [:project_id, :title], where: "project_id IS NOT NULL", name: INDEX_NAME, unique: true
  end
end
