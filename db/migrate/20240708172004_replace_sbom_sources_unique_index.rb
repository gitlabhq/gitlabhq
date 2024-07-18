# frozen_string_literal: true

class ReplaceSbomSourcesUniqueIndex < Gitlab::Database::Migration[2.2]
  REMOVED_INDEX_NAME = "index_sbom_sources_on_source_type_and_source"
  ADDED_INDEX_NAME = "index_sbom_sources_on_source_type_and_source_and_org_id"

  disable_ddl_transaction!

  milestone '17.3'

  def up
    add_concurrent_index :sbom_sources, %i[source_type source organization_id], unique: true, name: ADDED_INDEX_NAME
    remove_concurrent_index_by_name :sbom_sources, name: REMOVED_INDEX_NAME
  end

  def down
    add_concurrent_index :sbom_sources, %i[source_type source], unique: true, name: REMOVED_INDEX_NAME
    remove_concurrent_index_by_name :sbom_sources, name: ADDED_INDEX_NAME
  end
end
