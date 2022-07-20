# frozen_string_literal: true

class AddUsersAllowlistToGitRateLimits < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :git_rate_limit_users_allowlist,
      :text,
      array: true,
      default: [],
      null: false
  end
end
