# frozen_string_literal: true
class AddProjectsEmailsEnabledColumn < Gitlab::Database::Migration[2.0]
  enable_lock_retries!
  def change
    add_column :project_settings, :emails_enabled, :boolean, default: true, null: false
  end
end
