# frozen_string_literal: true

class CreateVirtualRegistriesPackagesNpmRegistryUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  TABLE_NAME = :virtual_registries_packages_npm_registry_upstreams

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { name: 'index_virtual_reg_pkgs_npm_reg_upstreams_on_group_id' },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.references :registry,
          null: false,
          index: false,
          foreign_key: { to_table: :virtual_registries_packages_npm_registries, on_delete: :cascade }
        t.references :upstream,
          null: false,
          index: false,
          foreign_key: { to_table: :virtual_registries_packages_npm_upstreams, on_delete: :cascade }

        t.timestamps_with_timezone null: false
        t.integer :position, limit: 2, null: false, default: 1

        t.index %i[upstream_id registry_id],
          unique: true,
          name: :v_reg_pkgs_npm_regs_upstreams_on_upstream_and_registry_ids
      end
    end

    constraint = check_constraint_name(TABLE_NAME, 'position', 'range')
    add_check_constraint(TABLE_NAME, '1 <= position AND position <= 20', constraint)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
