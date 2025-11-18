# frozen_string_literal: true

class Plan < ApplicationRecord
  DEFAULT = 'default'

  has_one :limits, class_name: 'PlanLimits'

  scope :by_name, ->(name) { where(name: name) }

  ALL_PLANS = [DEFAULT].freeze
  DEFAULT_PLANS = [DEFAULT].freeze
  private_constant :ALL_PLANS, :DEFAULT_PLANS

  PLAN_NAME_UID_LIST = {
    default: 1,
    free: 2,
    bronze: 3,
    silver: 4,
    premium: 5,
    gold: 6,
    ultimate: 7,
    ultimate_trial: 8,
    premium_trial: 9,
    ultimate_trial_paid_customer: 10,
    opensource: 11,
    early_adopter: 12
  }.freeze

  enum :plan_name_uid, PLAN_NAME_UID_LIST

  validates :plan_name_uid,
    presence: true,
    uniqueness: true,
    on: :create

  before_validation :set_plan_name_uid

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

  private

  def set_plan_name_uid
    return unless name.present?

    uid_value = self.class.plan_name_uids[name]
    self.plan_name_uid = uid_value if uid_value
  end
end

Plan.prepend_mod_with('Plan')
