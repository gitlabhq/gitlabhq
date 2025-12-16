# frozen_string_literal: true

class ReplaceZoektRepositoriesIndexForSchemaVersion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_concurrent_index :zoekt_repositories,
      [:zoekt_index_id, :state, :schema_version],
      name: :idx_zoekt_repositories_zoekt_index_id_state_schema_version

    remove_concurrent_index_by_name :zoekt_repositories, :idx_zoekt_repositories_on_zoekt_index_id_and_state_with_schema
  end

  def down
    add_concurrent_index :zoekt_repositories,
      [:zoekt_index_id, :state],
      include: [:schema_version],
      name: :idx_zoekt_repositories_on_zoekt_index_id_and_state_with_schema

    remove_concurrent_index_by_name :zoekt_repositories, :idx_zoekt_repositories_zoekt_index_id_state_schema_version
  end
end
