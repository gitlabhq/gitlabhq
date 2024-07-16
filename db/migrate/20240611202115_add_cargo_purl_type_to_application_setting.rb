# frozen_string_literal: true

class AddCargoPurlTypeToApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
  end

  CARGO_PURL_TYPE = 14

  def up
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types |= [CARGO_PURL_TYPE]
    application_setting.save
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types.delete(CARGO_PURL_TYPE)
    application_setting.save
  end
end
