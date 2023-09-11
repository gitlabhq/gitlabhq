# frozen_string_literal: true

class UpdatePackageMetadataSyncSetting < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
  end

  FULLY_ENABLED_SYNC = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].freeze

  def up
    application_setting = ApplicationSetting.last
    return unless application_setting

    # Check if the setting still has a default value and it wasn't updated manually by the admin
    return unless application_setting.package_metadata_purl_types == []

    # Update setting to enable all package types to sync
    application_setting.update(package_metadata_purl_types: FULLY_ENABLED_SYNC)
  end

  def down
    # no op
  end
end
