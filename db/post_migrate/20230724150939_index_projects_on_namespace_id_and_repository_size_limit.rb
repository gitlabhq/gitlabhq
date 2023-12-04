# frozen_string_literal: true

class IndexProjectsOnNamespaceIdAndRepositorySizeLimit < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_projects_on_namespace_id_and_repository_size_limit"

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/PreventIndexCreation
    add_concurrent_index :projects, [:namespace_id, :repository_size_limit], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index :projects, [:namespace_id, :repository_size_limit], name: INDEX_NAME
  end
end
