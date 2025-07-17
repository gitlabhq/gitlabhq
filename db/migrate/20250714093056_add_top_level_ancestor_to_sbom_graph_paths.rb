# frozen_string_literal: true

class AddTopLevelAncestorToSbomGraphPaths < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :sbom_graph_paths, :top_level_ancestor, :boolean, default: false, null: false
  end
end
