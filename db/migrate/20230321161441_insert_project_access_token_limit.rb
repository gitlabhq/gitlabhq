# frozen_string_literal: true

class InsertProjectAccessTokenLimit < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    create_or_update_plan_limit('project_access_token_limit', 'premium_trial', 1)
    create_or_update_plan_limit('project_access_token_limit', 'ultimate_trial', 1)
  end

  def down
    create_or_update_plan_limit('project_access_token_limit', 'premium_trial', 0)
    create_or_update_plan_limit('project_access_token_limit', 'ultimate_trial', 0)
  end
end
