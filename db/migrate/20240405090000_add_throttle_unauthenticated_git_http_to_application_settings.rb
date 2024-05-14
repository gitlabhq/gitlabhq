# frozen_string_literal: true

class AddThrottleUnauthenticatedGitHttpToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  def up
    add_column :application_settings, :rate_limits_unauthenticated_git_http, :jsonb, default: {}, null: false,
      if_not_exists: true

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(rate_limits_unauthenticated_git_http) = 'object')",
      'check_application_settings_rate_limits_unauth_git_http_is_hash'
    )
  end

  def down
    remove_column :application_settings, :rate_limits_unauthenticated_git_http, it_exists: true
  end
end
