# frozen_string_literal: true

class DropVirtualRegistriesPackagesMavenRegistriesCacheValidityHours < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  TABLE_NAME = :virtual_registries_packages_maven_registries

  def up
    remove_column TABLE_NAME, :cache_validity_hours, if_exists: true
  end

  def down
    add_column TABLE_NAME, :cache_validity_hours, :smallint, null: false, default: 1, if_not_exists: true

    constraint_name = check_constraint_name(TABLE_NAME.to_s, 'cache_validity_hours', 'zero_or_positive')
    add_check_constraint(TABLE_NAME, 'cache_validity_hours >= 0', constraint_name)
  end
end
