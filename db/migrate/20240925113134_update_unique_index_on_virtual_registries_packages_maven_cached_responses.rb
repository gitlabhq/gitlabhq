# frozen_string_literal: true

class UpdateUniqueIndexOnVirtualRegistriesPackagesMavenCachedResponses < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_cached_responses
  OLD_INDEX_NAME = 'idx_vregs_pkgs_mvn_cached_resp_on_uniq_upstrm_id_and_rel_path'
  NEW_INDEX_NAME = 'idx_vregs_pkgs_mvn_cached_resp_on_uniq_default_upt_id_relpath'
  ADDITIONAL_INDEX_NAME = 'idx_vregs_pkgs_mvn_cached_resp_on_upst_id_status_id'

  def up
    add_concurrent_index(
      TABLE_NAME,
      [:upstream_id, :relative_path],
      unique: true,
      name: NEW_INDEX_NAME,
      where: 'status = 0' # status: :default
    )
    add_concurrent_index(
      TABLE_NAME,
      [:upstream_id, :status, :id],
      name: ADDITIONAL_INDEX_NAME
    )
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      [:upstream_id, :relative_path],
      unique: true,
      name: OLD_INDEX_NAME
    )
    remove_concurrent_index_by_name(TABLE_NAME, ADDITIONAL_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
