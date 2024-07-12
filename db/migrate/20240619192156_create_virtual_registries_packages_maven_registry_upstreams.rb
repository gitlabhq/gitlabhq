# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenRegistryUpstreams < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { name: 'index_virtual_reg_pkgs_maven_reg_upstreams_on_group_id' },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.references :registry,
          null: false,
          index: { unique: true, name: 'virtual_reg_packages_maven_reg_upstreams_on_unique_reg_ids' },
          foreign_key: { to_table: :virtual_registries_packages_maven_registries, on_delete: :cascade }
        t.references :upstream,
          null: false,
          index: { unique: true, name: 'virtual_reg_packages_maven_reg_upstreams_on_unique_upstream_ids' },
          foreign_key: { to_table: :virtual_registries_packages_maven_upstreams, on_delete: :cascade }

        t.timestamps_with_timezone null: false
      end
    end
  end

  def down
    drop_table TABLE_NAME
  end
end
