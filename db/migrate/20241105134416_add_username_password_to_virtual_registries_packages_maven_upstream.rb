# frozen_string_literal: true

class AddUsernamePasswordToVirtualRegistriesPackagesMavenUpstream < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  TABLE_NAME = :virtual_registries_packages_maven_upstreams
  COLUMNS = %i[encrypted_username encrypted_username_iv encrypted_password encrypted_password_iv]

  def up
    with_lock_retries do
      # can't use COLUMNS.each here
      unless column_exists?(TABLE_NAME, :encrypted_username)
        add_column TABLE_NAME, :encrypted_username, :binary, null: true
      end

      unless column_exists?(TABLE_NAME, :encrypted_username_iv)
        add_column TABLE_NAME, :encrypted_username_iv, :binary, null: true
      end

      unless column_exists?(TABLE_NAME, :encrypted_password)
        add_column TABLE_NAME, :encrypted_password, :binary, null: true
      end

      unless column_exists?(TABLE_NAME, :encrypted_password_iv)
        add_column TABLE_NAME, :encrypted_password_iv, :binary, null: true
      end
    end

    add_concurrent_index TABLE_NAME,
      :encrypted_username_iv,
      unique: true,
      name: 'index_virtual_reg_pkgs_maven_upstreams_on_uniq_enc_username_iv'
    add_concurrent_index TABLE_NAME,
      :encrypted_password_iv,
      unique: true,
      name: 'index_virtual_reg_pkgs_maven_upstreams_on_uniq_enc_password_iv'

    COLUMNS.each do |col|
      constraint = check_constraint_name(TABLE_NAME.to_s, col.to_s, 'max_length')
      add_check_constraint(TABLE_NAME, "octet_length(#{col}) <= 1020", constraint)
    end
  end

  def down
    COLUMNS.each { |col| remove_column(TABLE_NAME, col, if_exists: true) }
  end
end
