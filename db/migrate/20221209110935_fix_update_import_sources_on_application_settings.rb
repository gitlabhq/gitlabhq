# frozen_string_literal: true

# This fixes 20221209110934_update_import_sources_on_application_settings.rb, which
# previously serialized a YAML column into a string.
class FixUpdateImportSourcesOnApplicationSettings < Gitlab::Database::Migration[2.0]
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
