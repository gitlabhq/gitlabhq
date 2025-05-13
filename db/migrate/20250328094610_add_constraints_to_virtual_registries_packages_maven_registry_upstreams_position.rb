# frozen_string_literal: true

class AddConstraintsToVirtualRegistriesPackagesMavenRegistryUpstreamsPosition < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams
  OLD_INDEX_NAME = 'virtual_reg_packages_maven_reg_upstreams_on_unique_reg_ids'
  NEW_INDEX_NAME = 'idx_vreg_pkgs_mvn_reg_upst_on_unique_regid_pos'

  def up
    add_concurrent_index TABLE_NAME,
      [:registry_id, :position],
      name: NEW_INDEX_NAME,
      unique: true
    remove_concurrent_index TABLE_NAME, :registry_id, name: OLD_INDEX_NAME

    constraint = check_constraint_name(TABLE_NAME, 'position', 'range')
    add_check_constraint(TABLE_NAME, '1 <= position AND position <= 20', constraint)
  end

  def down
    truncate_tables!(TABLE_NAME.to_s)
    constraint = check_constraint_name(TABLE_NAME, 'position', 'range')
    remove_check_constraint(TABLE_NAME, constraint)

    add_concurrent_index TABLE_NAME, :registry_id, unique: true, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, name: NEW_INDEX_NAME
  end
end
