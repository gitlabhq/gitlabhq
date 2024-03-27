# frozen_string_literal: true

class RemoveInstanceLevelCodeSuggestionsEnabled < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    remove_column :application_settings, :instance_level_code_suggestions_enabled, :boolean, null: false, default: false
  end
end
