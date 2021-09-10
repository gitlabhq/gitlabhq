# frozen_string_literal: true

class InsertDastProfileSchedulesPlanLimits < Gitlab::Database::Migration[1.0]
  def up
    create_or_update_plan_limit('dast_profile_schedules', 'default', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'free', 1)
    create_or_update_plan_limit('dast_profile_schedules', 'bronze', 1)
    create_or_update_plan_limit('dast_profile_schedules', 'silver', 1)
    create_or_update_plan_limit('dast_profile_schedules', 'premium', 1)
    create_or_update_plan_limit('dast_profile_schedules', 'premium_trial', 1)
    create_or_update_plan_limit('dast_profile_schedules', 'gold', 20)
    create_or_update_plan_limit('dast_profile_schedules', 'ultimate', 20)
    create_or_update_plan_limit('dast_profile_schedules', 'ultimate_trial', 20)
  end

  def down
    create_or_update_plan_limit('dast_profile_schedules', 'default', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'free', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'bronze', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'silver', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'premium', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'premium_trial', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'gold', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'ultimate', 0)
    create_or_update_plan_limit('dast_profile_schedules', 'ultimate_trial', 0)
  end
end
