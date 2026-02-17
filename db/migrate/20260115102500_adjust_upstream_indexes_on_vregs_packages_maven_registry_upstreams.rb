# frozen_string_literal: true

class AdjustUpstreamIndexesOnVregsPackagesMavenRegistryUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams
  OLD_IDX = :i_maven_reg_upstreams_on_upstream_and_registry_ids
  NEW_IDX = :idx_mvn_reg_upstreams_on_upstream_and_registry_ids

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[upstream_id registry_id],
      name: NEW_IDX,
      unique: true,
      where: 'upstream_id IS NOT NULL'
    )
    remove_concurrent_index_by_name(TABLE_NAME, OLD_IDX)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[upstream_id registry_id],
      name: OLD_IDX,
      unique: true
    )
    remove_concurrent_index_by_name(TABLE_NAME, NEW_IDX)
  end
end
