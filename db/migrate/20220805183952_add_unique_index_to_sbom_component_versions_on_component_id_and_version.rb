# frozen_string_literal: true

class AddUniqueIndexToSbomComponentVersionsOnComponentIdAndVersion < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_sbom_component_versions_on_component_id_and_version'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_component_versions, [:component_id, :version], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_component_versions, name: INDEX_NAME
  end
end
