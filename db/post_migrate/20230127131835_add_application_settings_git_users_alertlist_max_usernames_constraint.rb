# frozen_string_literal: true

class AddApplicationSettingsGitUsersAlertlistMaxUsernamesConstraint < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'app_settings_git_rate_limit_users_alertlist_max_usernames'

  disable_ddl_transaction!

  def up
    add_check_constraint :application_settings, 'CARDINALITY(git_rate_limit_users_alertlist) <= 100', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
