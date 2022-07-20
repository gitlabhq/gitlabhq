# frozen_string_literal: true

class AddApplicationSettingsGitUsersAllowlistMaxUsernamesConstraint < Gitlab::Database::Migration[2.0]
  CONSTRAINT_NAME = 'app_settings_git_rate_limit_users_allowlist_max_usernames'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'CARDINALITY(git_rate_limit_users_allowlist) <= 100', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
