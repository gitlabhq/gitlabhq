# frozen_string_literal: true

class AddGitRateLimitUsersAlertlistToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :git_rate_limit_users_alertlist,
      :integer,
      array: true,
      default: [],
      null: false
  end
end
