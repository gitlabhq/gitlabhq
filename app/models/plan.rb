# frozen_string_literal: true

class Plan < ApplicationRecord
  DEFAULT = 'default'.freeze

  has_one :limits, class_name: 'PlanLimits'

  ALL_PLANS = [DEFAULT].freeze
  DEFAULT_PLANS = [DEFAULT].freeze
  private_constant :ALL_PLANS, :DEFAULT_PLANS

  # This always returns an object
  def self.default
    Gitlab::SafeRequestStore.fetch(:plan_default) do
      # find_by allows us to find object (cheaply) against replica DB
      # safe_find_or_create_by does stick to primary DB
      find_by(name: DEFAULT) || safe_find_or_create_by(name: DEFAULT)
    end
  end

  def self.all_plans
    ALL_PLANS
  end

  def self.default_plans
    DEFAULT_PLANS
  end

  def default?
    self.class.default_plans.include?(name)
  end

  def paid?
    false
  end
end

Plan.prepend_if_ee('EE::Plan')
