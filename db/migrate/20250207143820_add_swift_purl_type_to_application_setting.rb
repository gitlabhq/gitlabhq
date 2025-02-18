# frozen_string_literal: true

class AddSwiftPurlTypeToApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
  end

  SWIFT_PURL_TYPE = 15

  def up
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types |= [SWIFT_PURL_TYPE]
    application_setting.save
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types.delete(SWIFT_PURL_TYPE)
    application_setting.save
  end
end
