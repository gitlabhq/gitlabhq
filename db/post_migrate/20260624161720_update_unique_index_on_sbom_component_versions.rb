# frozen_string_literal: true

class UpdateUniqueIndexOnSbomComponentVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  TABLE_NAME = :sbom_component_versions

  NEW_INDEX_NAME = :idx_sbom_comp_versions_on_comp_id_version_and_org_id
  OLD_INDEX_NAME = :index_sbom_component_versions_on_component_id_and_version

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[component_id version organization_id],
      unique: true,
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    # no-op
    #
    # The new index allows multiple rows with the same (component_id, version)
    # as long as organization_id differs. Recreating the previous unique index on
    # (component_id version) could fail on duplicate values, so this migration
    # is not safely reversible.
  end
end
