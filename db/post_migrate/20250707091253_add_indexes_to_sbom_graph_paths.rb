# frozen_string_literal: true

class AddIndexesToSbomGraphPaths < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.2'

  def up
    add_concurrent_index :sbom_graph_paths, %i[project_id path_length created_at],
      name: 'idx_sbom_graph_paths_project_path_length_created'

    add_concurrent_index :sbom_graph_paths, %i[project_id created_at],
      name: 'idx_sbom_graph_paths_project_created'
  end

  def down
    remove_concurrent_index_by_name :sbom_graph_paths, 'idx_sbom_graph_paths_project_path_length_created'
    remove_concurrent_index_by_name :sbom_graph_paths, 'idx_sbom_graph_paths_project_created'
  end
end
