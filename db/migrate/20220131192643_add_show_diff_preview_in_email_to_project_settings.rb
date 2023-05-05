# frozen_string_literal: true

class AddShowDiffPreviewInEmailToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :show_diff_preview_in_email, :boolean, default: true, null: false
  end
end
