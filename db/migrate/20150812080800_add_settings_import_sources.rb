require 'yaml'

class AddSettingsImportSources < ActiveRecord::Migration
  def change
    unless column_exists?(:application_settings, :import_sources)
      add_column :application_settings, :import_sources, :text
      import_sources = YAML::dump(Settings.gitlab['import_sources'])
      execute("update application_settings set import_sources = '#{import_sources}'")
    end
  end
end
