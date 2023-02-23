# frozen_string_literal: true

class RaiseCiVariableLimitsOnGitlabCom < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    create_or_update_plan_limit('project_ci_variables', 'free', 8000)
    create_or_update_plan_limit('project_ci_variables', 'bronze', 8000)
    create_or_update_plan_limit('project_ci_variables', 'silver', 8000)
    create_or_update_plan_limit('project_ci_variables', 'premium', 8000)
    create_or_update_plan_limit('project_ci_variables', 'premium_trial', 8000)
    create_or_update_plan_limit('project_ci_variables', 'gold', 8000)
    create_or_update_plan_limit('project_ci_variables', 'ultimate', 8000)
    create_or_update_plan_limit('project_ci_variables', 'ultimate_trial', 8000)
    create_or_update_plan_limit('project_ci_variables', 'early_adopter', 8000)
    create_or_update_plan_limit('project_ci_variables', 'opensource', 8000)

    create_or_update_plan_limit('group_ci_variables', 'free', 30000)
    create_or_update_plan_limit('group_ci_variables', 'bronze', 30000)
    create_or_update_plan_limit('group_ci_variables', 'silver', 30000)
    create_or_update_plan_limit('group_ci_variables', 'premium', 30000)
    create_or_update_plan_limit('group_ci_variables', 'premium_trial', 30000)
    create_or_update_plan_limit('group_ci_variables', 'gold', 30000)
    create_or_update_plan_limit('group_ci_variables', 'ultimate', 30000)
    create_or_update_plan_limit('group_ci_variables', 'ultimate_trial', 30000)
    create_or_update_plan_limit('group_ci_variables', 'early_adopter', 30000)
    create_or_update_plan_limit('group_ci_variables', 'opensource', 30000)
  end

  def down
    create_or_update_plan_limit('project_ci_variables', 'free', 200)
    create_or_update_plan_limit('project_ci_variables', 'bronze', 200)
    create_or_update_plan_limit('project_ci_variables', 'silver', 200)
    create_or_update_plan_limit('project_ci_variables', 'premium', 200)
    create_or_update_plan_limit('project_ci_variables', 'premium_trial', 200)
    create_or_update_plan_limit('project_ci_variables', 'gold', 200)
    create_or_update_plan_limit('project_ci_variables', 'ultimate', 200)
    create_or_update_plan_limit('project_ci_variables', 'ultimate_trial', 200)
    create_or_update_plan_limit('project_ci_variables', 'early_adopter', 200)
    create_or_update_plan_limit('project_ci_variables', 'opensource', 200)

    create_or_update_plan_limit('group_ci_variables', 'free', 200)
    create_or_update_plan_limit('group_ci_variables', 'bronze', 200)
    create_or_update_plan_limit('group_ci_variables', 'silver', 200)
    create_or_update_plan_limit('group_ci_variables', 'premium', 200)
    create_or_update_plan_limit('group_ci_variables', 'premium_trial', 200)
    create_or_update_plan_limit('group_ci_variables', 'gold', 200)
    create_or_update_plan_limit('group_ci_variables', 'ultimate', 200)
    create_or_update_plan_limit('group_ci_variables', 'ultimate_trial', 200)
    create_or_update_plan_limit('group_ci_variables', 'early_adopter', 200)
    create_or_update_plan_limit('group_ci_variables', 'opensource', 200)
  end
end
