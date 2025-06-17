# frozen_string_literal: true

class UpdateUniqIdxOnVirtualRegPkgsMvnGroupId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :virtual_registries_packages_maven_registries
  OLD_INDEX = :virtual_registries_pkgs_maven_registries_on_unique_group_ids
  NEW_INDEX = :virtual_reg_pkgs_mvn_registries_on_unique_group_id_and_name

  def up
    add_concurrent_index(
      :virtual_registries_packages_maven_registries,
      %i[group_id name],
      name: NEW_INDEX,
      unique: true
    )
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX)
  end

  def down
    add_concurrent_index(:virtual_registries_packages_maven_registries, :group_id, name: OLD_INDEX, unique: true)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX)
  end
end
