# frozen_string_literal: true

class SetApiRateLimitsToZero < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting

  milestone '18.0'

  def up
    return if Gitlab.com?

    set_groups_and_projects_api_rate_limits_to_zero
    set_users_api_rate_limits_to_zero
  end

  def down
    # no-op
  end

  private

  def set_groups_and_projects_api_rate_limits_to_zero
    connection.execute(<<~SQL)
      UPDATE application_settings
        SET rate_limits = rate_limits
          || '{"group_api_limit": 0}'::jsonb
          || '{"group_projects_api_limit": 0}'::jsonb
          || '{"group_shared_groups_api_limit": 0}'::jsonb
          || '{"groups_api_limit": 0}'::jsonb
          || '{"project_api_limit": 0}'::jsonb
          || '{"projects_api_limit": 0}'::jsonb
          || '{"user_contributed_projects_api_limit": 0}'::jsonb
          || '{"user_projects_api_limit": 0}'::jsonb
          || '{"user_starred_projects_api_limit": 0}'::jsonb;
    SQL
  end

  def set_users_api_rate_limits_to_zero
    connection.execute(<<~SQL)
      UPDATE application_settings
        SET rate_limits = rate_limits
          || '{"users_api_limit_followers": 0}'::jsonb
          || '{"users_api_limit_following": 0}'::jsonb
          || '{"users_api_limit_status": 0}'::jsonb
          || '{"users_api_limit_ssh_keys": 0}'::jsonb
          || '{"users_api_limit_ssh_key": 0}'::jsonb
          || '{"users_api_limit_gpg_keys": 0}'::jsonb
          || '{"users_api_limit_gpg_key": 0}'::jsonb;
    SQL
  end
end
