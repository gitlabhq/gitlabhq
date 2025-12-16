# frozen_string_literal: true

class CreateVirtualRegistriesPackagesNpmUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  TABLE_NAME = :virtual_registries_packages_npm_upstreams
  INDEX_NAME = :index_virtual_reg_pkgs_npm_upstreams_on_group_id

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { name: INDEX_NAME },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.timestamps_with_timezone null: false
        t.integer :cache_validity_hours, limit: 2, null: false, default: 24
        t.integer :metadata_cache_validity_hours, limit: 2, null: false, default: 24
        t.jsonb :username
        t.jsonb :password
        t.text :url, limit: 255, null: false
        t.text :name, limit: 255, null: false
        t.text :description, limit: 1024
      end
    end

    constraint = check_constraint_name(TABLE_NAME.to_s, 'cache_validity_hours', 'zero_or_positive')
    add_check_constraint(TABLE_NAME, 'cache_validity_hours >= 0', constraint)

    constraint = check_constraint_name(TABLE_NAME, 'metadata_cache_validity_hours', 'greater_than_zero')
    add_check_constraint(TABLE_NAME, 'metadata_cache_validity_hours > 0', constraint)

    constraint = check_constraint_name(TABLE_NAME, 'username_and_password', 'both_set_or_null')
    add_check_constraint(
      TABLE_NAME,
      'num_nonnulls(username, password) = 2 OR num_nulls(username, password) = 2',
      constraint
    )
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
