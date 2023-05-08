# frozen_string_literal: true

class RemoveGitlabImportSource < Gitlab::Database::Migration[2.1]
  include Gitlab::Utils::StrongMemoize
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class ApplicationSetting < MigrationRecord
  end

  def up
    return if import_sources.empty?

    new_sources = import_sources - ['gitlab']

    ApplicationSetting.update_all(import_sources: new_sources.to_yaml)
  end

  def down
    ## a reversion is not needed as the Gitlab.com importer is no longer
    #  a supported import source. Attempting to save it as one will result
    # in an ActiveRecord error.
  end

  def import_sources
    ## the last ApplicationSetting record is used to determine application settings
    import_sources = ApplicationSetting.last&.import_sources
    import_sources.nil? ? [] : YAML.safe_load(import_sources)
  end
  strong_memoize_attr(:import_sources)
end
