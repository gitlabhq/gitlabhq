# frozen_string_literal: true

class FixImportSourcesOnApplicationSettingsAfterPhabricatorRemoval < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
  end

  def up
    sources = ApplicationSetting.last&.import_sources

    return unless sources.is_a?(String)
    return if sources.start_with?('---')

    sources = YAML.safe_load(sources)

    ApplicationSetting.update_all(import_sources: sources.to_yaml)
  end

  def down; end
end
