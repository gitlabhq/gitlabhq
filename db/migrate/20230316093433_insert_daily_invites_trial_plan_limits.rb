# frozen_string_literal: true

class InsertDailyInvitesTrialPlanLimits < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('daily_invites', 'premium_trial', 50)
    create_or_update_plan_limit('daily_invites', 'ultimate_trial', 50)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('daily_invites', 'premium_trial', 0)
    create_or_update_plan_limit('daily_invites', 'ultimate_trial', 0)
  end
end
