# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenRegistries < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_registries
  INDEX_NAME = 'virtual_registries_pkgs_maven_registries_on_unique_group_ids'

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { unique: true, name: INDEX_NAME },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.timestamps_with_timezone null: false
        t.integer :cache_validity_hours, limit: 2, null: false, default: 1
      end
    end

    constraint = check_constraint_name(TABLE_NAME.to_s, 'cache_validity_hours', 'zero_or_positive')
    add_check_constraint(TABLE_NAME, 'cache_validity_hours >= 0', constraint)
  end

  def down
    drop_table TABLE_NAME
  end
end
