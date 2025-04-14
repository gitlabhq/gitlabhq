# frozen_string_literal: true

class RemoveNewUltimateTrialPlanFromCommunityEditionPlans < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless should_run?

    # NOTE: We have a uniqueness constraint for the 'name' column in 'plans'
    execute <<~SQL
      DELETE FROM plans
      WHERE name = 'ultimate_trial_paid_customer'
    SQL
  end

  def down
    return unless should_run?

    execute <<~SQL
      INSERT INTO plans (name, title, created_at, updated_at)
      VALUES ('ultimate_trial_paid_customer', 'Ultimate Trial for Paid Customer', current_timestamp, current_timestamp)
    SQL
  end

  private

  def should_run?
    !Gitlab.com?
  end
end
