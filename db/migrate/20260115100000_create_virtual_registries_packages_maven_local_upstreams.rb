# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenLocalUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_local_upstreams

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { name: 'index_virtual_reg_pkgs_maven_local_upstreams_on_group_id' },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.bigint :local_group_id, null: true
        t.bigint :local_project_id, null: true
        t.timestamps_with_timezone null: false
        t.integer :metadata_cache_validity_hours, default: 1, null: false, limit: 2
        t.integer :cache_validity_hours, default: 24, null: false, limit: 2
        t.text :name, null: false, default: '', limit: 255
        t.text :description, null: true, limit: 1024

        t.index :name,
          using: :gin,
          opclass: { name: :gin_trgm_ops },
          name: :idx_vreg_pkgs_mvn_local_upstreams_on_name_trigram

        t.index [:local_group_id, :group_id],
          unique: true,
          name: :idx_uniq_vreg_pkgs_mvn_local_upstr_on_loc_group_id_group_id,
          where: 'local_group_id IS NOT NULL'

        t.index [:local_project_id, :group_id],
          unique: true,
          name: :idx_uniq_vreg_pkgs_mvn_local_upstr_on_loc_proj_id_group_id,
          where: 'local_project_id IS NOT NULL'
      end
    end

    constraint = check_constraint_name(TABLE_NAME, 'metadata_cache_validity_hours', 'greater_than_zero')
    add_check_constraint(TABLE_NAME, 'metadata_cache_validity_hours > 0', constraint)

    constraint = check_constraint_name(TABLE_NAME, 'cache_validity_hours', 'greater_than_or_equal_to_zero')
    add_check_constraint(TABLE_NAME, 'cache_validity_hours >= 0', constraint)

    constraint = check_constraint_name(TABLE_NAME, 'local_upstream', 'mutually_exclusive')
    add_check_constraint(TABLE_NAME, 'num_nonnulls(local_group_id, local_project_id) = 1', constraint)
  end

  def down
    drop_table TABLE_NAME
  end
end
