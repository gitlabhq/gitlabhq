# frozen_string_literal: true

class RemoveUsernamePasswordCheckFromVirtualRegistriesPackagesNpmUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_npm_upstreams
  CONSTRAINT_NAME = :check_33b72b4447

  def up
    remove_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end

  def down
    return unless column_exists?(TABLE_NAME, :username) && column_exists?(TABLE_NAME, :password)

    add_check_constraint(
      TABLE_NAME,
      'num_nonnulls(username, password) = 2 OR num_nulls(username, password) = 2',
      CONSTRAINT_NAME
    )
  end
end
