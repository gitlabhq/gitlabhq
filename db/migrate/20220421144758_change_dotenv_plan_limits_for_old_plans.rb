# frozen_string_literal: true

class ChangeDotenvPlanLimitsForOldPlans < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    create_or_update_plan_limit('dotenv_variables', 'early_adopter', 50)
    create_or_update_plan_limit('dotenv_variables', 'bronze', 50)
    create_or_update_plan_limit('dotenv_variables', 'silver', 100)
    create_or_update_plan_limit('dotenv_variables', 'gold', 150)
  end

  def down
    create_or_update_plan_limit('dotenv_variables', 'early_adopter', 20)
    create_or_update_plan_limit('dotenv_variables', 'bronze', 20)
    create_or_update_plan_limit('dotenv_variables', 'silver', 20)
    create_or_update_plan_limit('dotenv_variables', 'gold', 20)
  end
end
