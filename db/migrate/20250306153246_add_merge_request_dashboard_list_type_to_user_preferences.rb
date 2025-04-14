# frozen_string_literal: true

class AddMergeRequestDashboardListTypeToUserPreferences < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :user_preferences, :merge_request_dashboard_list_type, :smallint, default: 0, null: false
  end
end
