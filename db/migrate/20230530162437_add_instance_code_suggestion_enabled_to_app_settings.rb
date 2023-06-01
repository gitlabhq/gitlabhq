# frozen_string_literal: true

class AddInstanceCodeSuggestionEnabledToAppSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :instance_level_code_suggestions_enabled, :boolean, null: false, default: false
  end
end
