# frozen_string_literal: true

class AddIndexToZoektRepositoriesSchemaVersion < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  INDEX_NAME = 'index_zoekt_repositories_on_schema_version'

  def up
    add_concurrent_index :zoekt_repositories, :schema_version, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_repositories, INDEX_NAME
  end
end
