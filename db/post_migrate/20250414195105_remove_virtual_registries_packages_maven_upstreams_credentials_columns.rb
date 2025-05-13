# frozen_string_literal: true

class RemoveVirtualRegistriesPackagesMavenUpstreamsCredentialsColumns < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  TABLE_NAME = :virtual_registries_packages_maven_upstreams
  COLUMNS = %i[encrypted_username encrypted_username_iv encrypted_password encrypted_password_iv]

  def up
    remove_columns(
      TABLE_NAME,
      *COLUMNS
    )
  end

  def down
    add_columns(
      TABLE_NAME,
      *COLUMNS,
      type: :binary
    )

    add_concurrent_index TABLE_NAME,
      :encrypted_username_iv,
      unique: true,
      name: 'index_virtual_reg_pkgs_maven_upstreams_on_uniq_enc_username_iv'
    add_concurrent_index TABLE_NAME,
      :encrypted_password_iv,
      unique: true,
      name: 'index_virtual_reg_pkgs_maven_upstreams_on_uniq_enc_password_iv'

    COLUMNS.each do |col|
      constraint = check_constraint_name(TABLE_NAME, col, 'max_length')
      add_check_constraint(TABLE_NAME, "octet_length(#{col}) <= 1020", constraint)
    end
  end
end
