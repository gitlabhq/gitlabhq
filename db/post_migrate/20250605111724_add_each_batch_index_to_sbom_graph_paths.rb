# frozen_string_literal: true

class AddEachBatchIndexToSbomGraphPaths < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.1'

  INDEX_NAME = "index_sbom_graph_paths_on_project_id_and_id"

  def up
    add_concurrent_index :sbom_graph_paths, %i[project_id id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_graph_paths, INDEX_NAME
  end
end
