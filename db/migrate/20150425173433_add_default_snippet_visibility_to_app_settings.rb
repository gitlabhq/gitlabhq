class AddDefaultSnippetVisibilityToAppSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :default_snippet_visibility, :integer
    visibility = Settings.gitlab.default_projects_features['visibility_level']
    execute("update application_settings set default_snippet_visibility = #{visibility}")
  end
end
