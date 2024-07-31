# frozen_string_literal: true

class ReplaceSbomSourcePackagesUniqueIndex < Gitlab::Database::Migration[2.2]
  ADDED_INDEX_NAME = "index_sbom_source_packages_on_name_and_purl_type_and_org_id"

  disable_ddl_transaction!

  milestone '17.3'

  def up
    add_concurrent_index :sbom_source_packages, %i[name purl_type organization_id], unique: true, name: ADDED_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_source_packages, name: ADDED_INDEX_NAME
  end
end
