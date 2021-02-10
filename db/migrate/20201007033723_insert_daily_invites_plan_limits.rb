# frozen_string_literal: true

class InsertDailyInvitesPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('daily_invites', 'free', 20)
    create_or_update_plan_limit('daily_invites', 'bronze', 0)
    create_or_update_plan_limit('daily_invites', 'silver', 0)
    create_or_update_plan_limit('daily_invites', 'gold', 0)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('daily_invites', 'free', 0)
    create_or_update_plan_limit('daily_invites', 'bronze', 0)
    create_or_update_plan_limit('daily_invites', 'silver', 0)
    create_or_update_plan_limit('daily_invites', 'gold', 0)
  end
end
