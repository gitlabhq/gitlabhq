# frozen_string_literal: true

class AddPartialIndexOnTopLevelAncestorToSbomGraphPaths < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  INDEX_NAME = "index_sbom_graph_paths_on_descendant_id_created_at_top_level"

  def up
    add_concurrent_index :sbom_graph_paths, %i[descendant_id created_at], where: "top_level_ancestor = TRUE",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_graph_paths, INDEX_NAME
  end
end
