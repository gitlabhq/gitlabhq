# frozen_string_literal: true

class MovePackageRegistryApplicationSettingsToJsonbColumn < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  PACKAGE_REGISTRY_COLUMNS = %w[
    package_registry_allow_anyone_to_pull_option
    package_registry_cleanup_policies_worker_capacity
    packages_cleanup_package_file_worker_capacity
    npm_package_requests_forwarding
    lock_npm_package_requests_forwarding
    maven_package_requests_forwarding
    lock_maven_package_requests_forwarding
    pypi_package_requests_forwarding
    lock_pypi_package_requests_forwarding
  ].freeze

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    application_setting = ApplicationSetting.lock.last
    return unless application_setting

    package_registry_settings = application_setting.attribute_in_database(:package_registry)

    PACKAGE_REGISTRY_COLUMNS.each do |column_name|
      package_registry_settings[column_name] = application_setting.attribute_in_database(column_name)
    end

    application_setting.update_columns(package_registry: package_registry_settings, updated_at: Time.current)
  end

  def down
    application_setting = ApplicationSetting.lock.last
    return unless application_setting

    package_registry_settings = application_setting.attribute_in_database(:package_registry)
    package_registry_settings.except!(*PACKAGE_REGISTRY_COLUMNS)

    application_setting.update_columns(package_registry: package_registry_settings)
  end
end
