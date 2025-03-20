# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateVSCodeExtensionMarketplaceFeatureFlagToData < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.10'

  # NOTE: This approach is lovingly borrowed from this migration:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/eae8739ac9d5e4c8316fefb03507cdaeac452a0a/db/migrate/20250109055316_migrate_global_search_settings_in_application_settings.rb#L12
  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    # TODO: This migration should be noop'd when the feature flag is default enabled or removed
    # why: This is not the desired default behavior, only the behavior we want to carry over for
    # customers that have chosen to opt-in early by explicitly enabling the flag.
    return unless extension_marketplace_flag_enabled?

    ApplicationSetting.reset_column_information

    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.update_columns(
      vscode_extension_marketplace: { enabled: true, preset: "open_vsx" },
      updated_at: Time.current
    )
  end

  def down
    return unless extension_marketplace_flag_enabled?

    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.update_column(:vscode_extension_marketplace, {})
  end

  private

  def extension_marketplace_flag_enabled?
    # NOTE: It's possible the flag is only enabled for a specific user, but in that case we'll assume
    # the instance admin didn't want the feature globally available and we won't initialize the data.
    Feature.enabled?(:web_ide_extensions_marketplace, nil) &&
      # NOTE: We only want to migrate instances that have **explicitly** opted in to the early
      # extensions marketplace experience (not just enabled by default feature flag).
      Feature.persisted_name?(:web_ide_extensions_marketplace) &&
      Feature.enabled?(:vscode_web_ide, nil)
  end
end
