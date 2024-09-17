# frozen_string_literal: true

class ReplaceSbomComponentsUniqueIndex < Gitlab::Database::Migration[2.2]
  ADDED_INDEX_NAME = "idx_sbom_components_on_name_purl_type_component_type_and_org_id"

  disable_ddl_transaction!

  milestone '17.3'

  def up
    add_concurrent_index :sbom_components,
      %i[name purl_type component_type organization_id],
      unique: true,
      name: ADDED_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_components, name: ADDED_INDEX_NAME
  end
end
