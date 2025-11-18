# frozen_string_literal: true

class BackfillPlanNameUidOnPlans < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.6'

  def up
    execute <<~SQL
      UPDATE plans
      SET plan_name_uid = CASE name
        WHEN 'default' THEN 1
        WHEN 'free' THEN 2
        WHEN 'bronze' THEN 3
        WHEN 'silver' THEN 4
        WHEN 'premium' THEN 5
        WHEN 'gold' THEN 6
        WHEN 'ultimate' THEN 7
        WHEN 'ultimate_trial' THEN 8
        WHEN 'premium_trial' THEN 9
        WHEN 'ultimate_trial_paid_customer' THEN 10
        WHEN 'opensource' THEN 11
        WHEN 'early_adopter' THEN 12
      END
    SQL
  end

  def down
    # no-op
  end
end
