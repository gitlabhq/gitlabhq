# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddWolfiPurlTypeToPackageMetadataPurlTypes < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
  end

  WOLFI_PURL_TYPE = 13

  def up
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types |= [WOLFI_PURL_TYPE]
    application_setting.save
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.package_metadata_purl_types.delete(WOLFI_PURL_TYPE)
    application_setting.save
  end
end
