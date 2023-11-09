# frozen_string_literal: true

class AddZoektNodeIdToIndexedNamespaces < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  def up
    add_column :zoekt_indexed_namespaces, :zoekt_node_id, :bigint
  end

  def down
    remove_column :zoekt_indexed_namespaces, :zoekt_node_id
  end
end
