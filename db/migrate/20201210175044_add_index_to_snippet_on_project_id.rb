# frozen_string_literal: true

class AddIndexToSnippetOnProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  INDEX_NAME = "index_snippet_on_id_and_project_id"
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :snippets, [:id, :project_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippets, INDEX_NAME
  end
end
