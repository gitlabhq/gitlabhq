# frozen_string_literal: true

class AddPubPurlTypeToApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
  end

  PUB_PURL_TYPE = 17

  def up
    ApplicationSetting.reset_column_information
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types |= [PUB_PURL_TYPE]
    application_setting.save
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types.delete(PUB_PURL_TYPE)
    application_setting.save
  end
end
