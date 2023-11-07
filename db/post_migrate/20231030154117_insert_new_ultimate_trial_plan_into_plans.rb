# frozen_string_literal: true

class InsertNewUltimateTrialPlanIntoPlans < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      INSERT INTO plans (name, title, created_at, updated_at)
      VALUES ('ultimate_trial_paid_customer', 'Ultimate Trial for Paid Customer', current_timestamp, current_timestamp)
    SQL
  end

  def down
    # NOTE: We have a uniqueness constraint for the 'name' column in 'plans'
    execute <<~SQL
      DELETE FROM plans
      WHERE name = 'ultimate_trial_paid_customer'
    SQL
  end
end
