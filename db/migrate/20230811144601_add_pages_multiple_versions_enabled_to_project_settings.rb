# frozen_string_literal: true

class AddPagesMultipleVersionsEnabledToProjectSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :project_settings, :pages_multiple_versions_enabled, :boolean, default: false, null: false
  end
end
