# frozen_string_literal: true

class DropVirtualRegistriesPackagesMavenUpstreamsEncryptedCredentials < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  TABLE_NAME = :virtual_registries_packages_maven_upstreams

  def up
    remove_column TABLE_NAME, :encrypted_credentials, if_exists: true
    remove_column TABLE_NAME, :encrypted_credentials_iv, if_exists: true
  end

  def down
    add_column TABLE_NAME, :encrypted_credentials, :binary, null: true, if_not_exists: true
    add_column TABLE_NAME, :encrypted_credentials_iv, :binary, null: true, if_not_exists: true

    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_credentials) <= 1020', 'check_b9e3bfa31a')
    add_check_constraint(TABLE_NAME, 'octet_length(encrypted_credentials_iv) <= 1020', 'check_4af2999ab8')
  end
end
