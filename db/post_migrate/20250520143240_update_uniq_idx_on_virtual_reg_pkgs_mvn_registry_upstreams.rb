# frozen_string_literal: true

class UpdateUniqIdxOnVirtualRegPkgsMvnRegistryUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams
  OLD_INDEX = :virtual_reg_packages_maven_reg_upstreams_on_unique_upstream_ids
  NEW_INDEX = :i_maven_reg_upstreams_on_upstream_and_registry_ids

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[upstream_id registry_id],
      name: NEW_INDEX,
      unique: true
    )
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX)
  end

  def down
    add_concurrent_index(TABLE_NAME, :upstream_id, name: OLD_INDEX, unique: true)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX)
  end
end
