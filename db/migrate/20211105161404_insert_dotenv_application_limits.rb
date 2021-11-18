# frozen_string_literal: true

class InsertDotenvApplicationLimits < Gitlab::Database::Migration[1.0]
  def up
    create_or_update_plan_limit('dotenv_variables', 'default', 150)
    create_or_update_plan_limit('dotenv_variables', 'free', 50)
    create_or_update_plan_limit('dotenv_variables', 'opensource', 150)
    create_or_update_plan_limit('dotenv_variables', 'premium', 100)
    create_or_update_plan_limit('dotenv_variables', 'premium_trial', 100)
    create_or_update_plan_limit('dotenv_variables', 'ultimate', 150)
    create_or_update_plan_limit('dotenv_variables', 'ultimate_trial', 150)

    create_or_update_plan_limit('dotenv_size', 'default', 5.kilobytes)
  end

  def down
    create_or_update_plan_limit('dotenv_variables', 'default', 20)
    create_or_update_plan_limit('dotenv_variables', 'free', 20)
    create_or_update_plan_limit('dotenv_variables', 'opensource', 20)
    create_or_update_plan_limit('dotenv_variables', 'premium', 20)
    create_or_update_plan_limit('dotenv_variables', 'premium_trial', 20)
    create_or_update_plan_limit('dotenv_variables', 'ultimate', 20)
    create_or_update_plan_limit('dotenv_variables', 'ultimate_trial', 20)

    create_or_update_plan_limit('dotenv_size', 'default', 5.kilobytes)
  end
end
