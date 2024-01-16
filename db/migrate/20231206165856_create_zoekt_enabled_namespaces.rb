# frozen_string_literal: true

class CreateZoektEnabledNamespaces < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  UNIQUE_ROOT_NAMESPACE_ID_INDEX_NAME = 'unique_zoekt_enabled_namespaces_on_root_namespace_id'
  SEARCH_INDEX_NAME = 'index_zoekt_enabled_namespaces_on_search'

  def change
    create_table :zoekt_enabled_namespaces do |t|
      t.bigint :root_namespace_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :search, null: false, default: true

      t.index :root_namespace_id, unique: true, name: UNIQUE_ROOT_NAMESPACE_ID_INDEX_NAME, using: :btree
    end
  end
end
