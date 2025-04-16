# frozen_string_literal: true

class RemoveApplicationSettingsPackageRegistryIndividualColumns < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  TABLE_NAME = :application_settings

  def up
    remove_columns(
      TABLE_NAME,
      :package_registry_allow_anyone_to_pull_option,
      :package_registry_cleanup_policies_worker_capacity,
      :packages_cleanup_package_file_worker_capacity,
      :npm_package_requests_forwarding,
      :lock_npm_package_requests_forwarding,
      :maven_package_requests_forwarding,
      :lock_maven_package_requests_forwarding,
      :pypi_package_requests_forwarding,
      :lock_pypi_package_requests_forwarding
    )
  end

  def down
    add_column TABLE_NAME, :package_registry_allow_anyone_to_pull_option, :boolean, default: true, null: false
    add_column TABLE_NAME, :package_registry_cleanup_policies_worker_capacity, :integer, default: 2, null: false
    add_column TABLE_NAME, :packages_cleanup_package_file_worker_capacity, :smallint, default: 2, null: false
    add_column TABLE_NAME, :npm_package_requests_forwarding, :boolean, default: true, null: false
    add_column TABLE_NAME, :lock_npm_package_requests_forwarding, :boolean, default: false, null: false
    add_column TABLE_NAME, :maven_package_requests_forwarding, :boolean, default: true, null: false
    add_column TABLE_NAME, :lock_maven_package_requests_forwarding, :boolean, default: false, null: false
    add_column TABLE_NAME, :pypi_package_requests_forwarding, :boolean, default: true, null: false
    add_column TABLE_NAME, :lock_pypi_package_requests_forwarding, :boolean, default: false, null: false

    add_check_constraint TABLE_NAME,
      'package_registry_cleanup_policies_worker_capacity >= 0',
      'app_settings_pkg_registry_cleanup_pol_worker_capacity_gte_zero'

    add_check_constraint TABLE_NAME,
      'packages_cleanup_package_file_worker_capacity >= 0',
      'app_settings_p_cleanup_package_file_worker_capacity_positive'
  end
end
