# frozen_string_literal: true

class CreateVirtualRegistriesPackagesMavenUpstreams < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_upstreams

  def up
    with_lock_retries do
      create_table TABLE_NAME, if_not_exists: true do |t|
        t.references :group,
          null: false,
          index: { name: 'index_virtual_reg_pkgs_maven_upstreams_on_group_id' },
          foreign_key: { to_table: :namespaces, on_delete: :cascade }
        t.timestamps_with_timezone null: false
        t.text :url, null: false, limit: 255
        t.binary :encrypted_credentials, null: true
        t.binary :encrypted_credentials_iv, null: true
      end
    end

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_credentials', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_credentials) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_credentials_iv', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_credentials_iv) <= 1020', constraint)
  end

  def down
    drop_table TABLE_NAME
  end
end
