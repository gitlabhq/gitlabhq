# frozen_string_literal: true

class AddSearchToZoektNamespace < Gitlab::Database::Migration[2.1]
  def change
    add_column :zoekt_indexed_namespaces, :search, :boolean, default: true, null: false
  end
end
