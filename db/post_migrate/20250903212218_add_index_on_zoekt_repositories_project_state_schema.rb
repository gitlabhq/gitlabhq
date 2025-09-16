# frozen_string_literal: true

class AddIndexOnZoektRepositoriesProjectStateSchema < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'idx_zoekt_repositories_project_state_schema'

  def up
    add_concurrent_index :zoekt_repositories, [:project_identifier, :state, :schema_version], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_repositories, INDEX_NAME
  end
end
