# frozen_string_literal: true

class DropIndexOnComponentVersionsByComponentId < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  INDEX_NAME = 'index_sbom_component_versions_on_component_id'

  def up
    remove_concurrent_index_by_name :sbom_component_versions, INDEX_NAME
  end

  def down
    add_concurrent_index :sbom_component_versions, :component_id, name: INDEX_NAME
  end
end
