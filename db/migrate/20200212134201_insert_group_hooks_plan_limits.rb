# frozen_string_literal: true

class InsertGroupHooksPlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.com?

    create_or_update_plan_limit('group_hooks', 'bronze', 50)
    create_or_update_plan_limit('group_hooks', 'silver', 50)
    create_or_update_plan_limit('group_hooks', 'gold', 50)
  end

  def down
    return unless Gitlab.com?

    create_or_update_plan_limit('group_hooks', 'bronze', 0)
    create_or_update_plan_limit('group_hooks', 'silver', 0)
    create_or_update_plan_limit('group_hooks', 'gold', 0)
  end
end
