# frozen_string_literal: true

class AddNewTrailPlans < ActiveRecord::Migration[6.0]
  class Plan < ActiveRecord::Base
    self.inheritance_column = :_type_disabled

    has_one :limits, class_name: 'PlanLimits'

    def actual_limits
      self.limits || self.build_limits
    end
  end

  class PlanLimits < ActiveRecord::Base
    self.inheritance_column = :_type_disabled

    belongs_to :plan
  end

  def create_plan_limits(plan_limit_name, plan)
    plan_limit = Plan.find_or_initialize_by(name: plan_limit_name).actual_limits.dup
    plan_limit.plan = plan
    plan_limit.save!
  end

  def up
    return unless Gitlab.dev_env_or_com?

    ultimate_trial = Plan.create!(name: 'ultimate_trial', title: 'Ultimate Trial')
    premium_trial = Plan.create!(name: 'premium_trial', title: 'Premium Trial')

    create_plan_limits('gold', ultimate_trial)
    create_plan_limits('silver', premium_trial)
  end

  def down
    return unless Gitlab.dev_env_or_com?

    Plan.where(name: %w(ultimate_trial premium_trial)).delete_all
  end
end
