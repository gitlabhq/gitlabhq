# frozen_string_literal: true

class AddUsernamePasswordToVirtualRegistriesPackagesMavenUpstreams < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_upstreams

  def up
    with_lock_retries do
      add_column TABLE_NAME, :username, :jsonb, null: true, if_not_exists: true
      add_column TABLE_NAME, :password, :jsonb, null: true, if_not_exists: true
    end

    add_check_constraint TABLE_NAME,
      'num_nonnulls(username, password) = 2 OR num_nulls(username, password) = 2',
      check_constraint_name(TABLE_NAME, 'username_and_password', 'both_set_or_null')
  end

  def down
    with_lock_retries do
      remove_column(TABLE_NAME, :username, if_exists: true)
      remove_column(TABLE_NAME, :password, if_exists: true)
    end
  end
end
