# frozen_string_literal: true

class SetApplicationSettingsDefaultProjectAndSnippetVisibility < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null :application_settings, :default_project_visibility, false, 0
    change_column_default :application_settings, :default_project_visibility, from: nil, to: 0

    change_column_null :application_settings, :default_snippet_visibility, false, 0
    change_column_default :application_settings, :default_snippet_visibility, from: nil, to: 0
  end
end
