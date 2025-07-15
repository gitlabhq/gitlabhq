# frozen_string_literal: true

class AddAllActiveProjectIdsColumnToNamespaceDescendants < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :namespace_descendants, :all_active_project_ids, 'bigint[]', default: [], null: false
  end
end
