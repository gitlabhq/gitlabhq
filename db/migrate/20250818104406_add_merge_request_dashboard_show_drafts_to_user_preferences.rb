# frozen_string_literal: true

class AddMergeRequestDashboardShowDraftsToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :user_preferences, :merge_request_dashboard_show_drafts, :boolean, default: true, null: false
  end
end
