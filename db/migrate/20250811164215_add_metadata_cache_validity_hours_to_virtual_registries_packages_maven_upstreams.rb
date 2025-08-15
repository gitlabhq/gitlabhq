# frozen_string_literal: true

class AddMetadataCacheValidityHoursToVirtualRegistriesPackagesMavenUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = :virtual_registries_packages_maven_upstreams

  def up
    with_lock_retries do
      add_column TABLE_NAME, :metadata_cache_validity_hours, :smallint, default: 24, null: false, if_not_exists: true
    end

    constraint = check_constraint_name(TABLE_NAME, 'metadata_cache_validity_hours', 'greater_than_zero')
    add_check_constraint(TABLE_NAME, 'metadata_cache_validity_hours > 0', constraint)
  end

  def down
    remove_column TABLE_NAME, :metadata_cache_validity_hours, if_exists: true
  end
end
