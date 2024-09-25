# frozen_string_literal: true

class DropIdxSbomSourcePackagesOnNameAndPurlType < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.5'

  INDEX_NAME = 'idx_sbom_source_packages_on_name_and_purl_type'

  def up
    remove_concurrent_index_by_name :sbom_source_packages, INDEX_NAME
  end

  def down
    # no-op, we don't want to re-introduce this index as it is redundant with
    # index_sbom_source_packages_on_name_and_purl_type_and_org_id
  end
end
