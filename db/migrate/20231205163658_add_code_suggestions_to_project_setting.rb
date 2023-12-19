# frozen_string_literal: true

class AddCodeSuggestionsToProjectSetting < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def change
    add_column :project_settings, :code_suggestions, :boolean, default: true, null: false
  end
end
