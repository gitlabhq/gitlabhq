# frozen_string_literal: true

class AddOpenSourcePlan < Gitlab::Database::Migration[1.0]
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
    return unless Gitlab.com?

    opensource = Plan.create!(name: 'opensource', title: 'Open Source Program')

    create_plan_limits('ultimate', opensource)
  end

  def down
    return unless Gitlab.com?

    Plan.where(name: 'opensource').delete_all
  end
end
