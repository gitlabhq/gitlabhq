# frozen_string_literal: true

class AddSuggestedReviewersEnabledToProjectSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :suggested_reviewers_enabled, :boolean, default: false, null: false
  end
end
