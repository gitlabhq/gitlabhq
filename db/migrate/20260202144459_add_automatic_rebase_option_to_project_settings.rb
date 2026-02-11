# frozen_string_literal: true

class AddAutomaticRebaseOptionToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :project_settings, :automatic_rebase_enabled, :boolean, default: false, null: false
  end
end
