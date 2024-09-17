# frozen_string_literal: true

class Plan < ApplicationRecord
  DEFAULT = 'default'

  has_one :limits, class_name: 'PlanLimits'

  scope :by_name, ->(name) { where(name: name) }

  ALL_PLANS = [DEFAULT].freeze
  DEFAULT_PLANS = [DEFAULT].freeze
  private_constant :ALL_PLANS, :DEFAULT_PLANS

  # This always returns an object
  def self.default
    Gitlab::SafeRequestStore.fetch(:plan_default) do
      # find_by allows us to find object (cheaply) against replica DB
      # safe_find_or_create_by does stick to primary DB
      find_by(name: DEFAULT) || safe_find_or_create_by(name: DEFAULT) { |plan| plan.title = DEFAULT.titleize }
    end
  end

  def self.all_plans
    ALL_PLANS
  end

  def self.default_plans
    DEFAULT_PLANS
  end

  # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- This method is prepared for manual usage in
  # Rails console on SaaS. Using pluck without limit in this case should be enough safe.
  def self.ids_for_names(names)
    self.where(name: names).pluck(:id)
  end
  # rubocop: enable Database/AvoidUsingPluckWithoutLimit

  # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- This method is prepared for manual usage in
  # Rails console on SaaS. Using pluck without limit in this case should be enough safe.
  def self.names_for_ids(plan_ids)
    self.id_in(plan_ids).pluck(:name)
  end
  # rubocop: enable Database/AvoidUsingPluckWithoutLimit

  def actual_limits
    self.limits || self.build_limits
  end

  def default?
    self.class.default_plans.include?(name)
  end

  def paid?
    false
  end
end

Plan.prepend_mod_with('Plan')
