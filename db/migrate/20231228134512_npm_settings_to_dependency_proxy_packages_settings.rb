# frozen_string_literal: true

class NpmSettingsToDependencyProxyPackagesSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = :dependency_proxy_packages_settings

  def up
    # using the table name so that Migration/AddLimitToTextColumns cop will not make rubocop fail.
    change_table :dependency_proxy_packages_settings do |t|
      t.text :npm_external_registry_url, null: true
      t.binary :encrypted_npm_external_registry_basic_auth, null: true
      t.binary :encrypted_npm_external_registry_basic_auth_iv, null: true
      t.binary :encrypted_npm_external_registry_auth_token, null: true
      t.binary :encrypted_npm_external_registry_auth_token_iv, null: true
    end

    # using the table name so that Migration/AddLimitToTextColumns cop will not make rubocop fail.
    add_text_limit :dependency_proxy_packages_settings, :npm_external_registry_url, 255

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_npm_external_registry_basic_auth', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_npm_external_registry_basic_auth) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_npm_external_registry_basic_auth_iv', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_npm_external_registry_basic_auth_iv) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_npm_external_registry_auth_token', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_npm_external_registry_auth_token) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'encrypted_npm_external_registry_auth_token_iv', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_npm_external_registry_auth_token_iv) <= 1020', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'npm_credentials', 'one_set_or_empty')
    add_check_constraint(
      TABLE_NAME,
      'num_nulls(encrypted_npm_external_registry_basic_auth, encrypted_npm_external_registry_auth_token) > 0',
      constraint
    )
  end

  def down
    change_table TABLE_NAME do |t|
      t.remove :npm_external_registry_url,
        :encrypted_npm_external_registry_basic_auth,
        :encrypted_npm_external_registry_basic_auth_iv,
        :encrypted_npm_external_registry_auth_token,
        :encrypted_npm_external_registry_auth_token_iv
    end
  end
end
