# frozen_string_literal: true

class AddCacheValidityHoursToVirtualRegistriesPackagesMavenUpstreams < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_upstreams

  def up
    with_lock_retries do
      add_column TABLE_NAME, :cache_validity_hours, :smallint, default: 24, null: false, if_not_exists: true
    end

    constraint = check_constraint_name(TABLE_NAME.to_s, 'cache_validity_hours', 'zero_or_positive')
    add_check_constraint(TABLE_NAME, 'cache_validity_hours >= 0', constraint)
  end

  def down
    remove_column TABLE_NAME, :cache_validity_hours, if_exists: true
  end
end
