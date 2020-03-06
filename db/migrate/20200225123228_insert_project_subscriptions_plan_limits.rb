# frozen_string_literal: true

class InsertProjectSubscriptionsPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return if Rails.env.test?

    if Gitlab.com?
      create_or_update_plan_limit('ci_project_subscriptions', 'free', 2)
      create_or_update_plan_limit('ci_project_subscriptions', 'bronze', 2)
      create_or_update_plan_limit('ci_project_subscriptions', 'silver', 2)
      create_or_update_plan_limit('ci_project_subscriptions', 'gold', 2)
    else
      create_or_update_plan_limit('ci_project_subscriptions', 'default', 2)
    end
  end

  def down
    return if Rails.env.test?

    if Gitlab.com?
      create_or_update_plan_limit('ci_project_subscriptions', 'free', 0)
      create_or_update_plan_limit('ci_project_subscriptions', 'bronze', 0)
      create_or_update_plan_limit('ci_project_subscriptions', 'silver', 0)
      create_or_update_plan_limit('ci_project_subscriptions', 'gold', 0)
    else
      create_or_update_plan_limit('ci_project_subscriptions', 'default', 0)
    end
  end
end
