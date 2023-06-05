# frozen_string_literal: true

class CreateDependencyProxyPackagesSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :dependency_proxy_packages_settings

  def up
    with_lock_retries do
      create_table TABLE_NAME, id: false, if_not_exists: true do |t|
        t.timestamps_with_timezone null: false

        t.references :project,
          primary_key: true,
          default: nil,
          index: false,
          foreign_key: { to_table: :projects, on_delete: :cascade }

        t.boolean :enabled, default: false
        t.text :maven_external_registry_url, null: true, limit: 255
        t.binary :encrypted_maven_external_registry_username, null: true
        t.binary :encrypted_maven_external_registry_username_iv, null: true
        t.binary :encrypted_maven_external_registry_password, null: true
        t.binary :encrypted_maven_external_registry_password_iv, null: true
      end
    end

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_maven_external_registry_username', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_maven_external_registry_username) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_maven_external_registry_username_iv', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_maven_external_registry_username_iv) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_maven_external_registry_password', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_maven_external_registry_password) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_maven_external_registry_password_iv', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_maven_external_registry_password_iv) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'maven_credentials', 'set_or_empty')
    add_check_constraint(
      TABLE_NAME,
      '(num_nulls(encrypted_maven_external_registry_username, encrypted_maven_external_registry_password) = 0)
       OR
       (num_nulls(encrypted_maven_external_registry_username, encrypted_maven_external_registry_password) = 2)',
      constraint
    )
  end

  def down
    drop_table TABLE_NAME
  end
end
