# frozen_string_literal: true

class DropIndexSbomComponentsOnComponentTypeNameAndPurlType < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.5'

  INDEX_NAME = 'index_sbom_components_on_component_type_name_and_purl_type'

  def up
    remove_concurrent_index_by_name :sbom_components, INDEX_NAME
  end

  def down
    # no-op, we don't want to re-introduce this index as it is redundant with
    # idx_sbom_components_on_name_purl_type_component_type_and_org_id
  end
end
