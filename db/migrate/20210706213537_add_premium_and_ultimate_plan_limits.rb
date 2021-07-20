# frozen_string_literal: true

class AddPremiumAndUltimatePlanLimits < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  class Plan < ActiveRecord::Base
    self.inheritance_column = :_type_disabled

    has_one :limits, class_name: 'PlanLimits'
  end

  class PlanLimits < ActiveRecord::Base
    self.inheritance_column = :_type_disabled

    belongs_to :plan
  end

  def copy_plan_limits(from_plan_name:, to_plan_name:)
    source_plan = Plan.find_by(name: from_plan_name)
    target_plan = Plan.find_by(name: to_plan_name)
    return unless source_plan && target_plan
    return unless source_plan.limits.present?
    return if target_plan.limits.present?

    limits = source_plan.limits.dup
    limits.plan = target_plan
    limits.save!
  end

  def up
    return unless Gitlab.com?

    copy_plan_limits(from_plan_name: 'gold', to_plan_name: 'ultimate')
    copy_plan_limits(from_plan_name: 'silver', to_plan_name: 'premium')
  end

  def down
    # no-op
  end
end
