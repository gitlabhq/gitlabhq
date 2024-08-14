# frozen_string_literal: true

class SetImportPlaceholderLimitsForPlanLimits < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  LOW_LIMITS = ([200] * 4).freeze
  MID_LIMITS = [500, 2_000, 4_000, 6_000].freeze
  HIGH_LIMITS = [1_000, 4_000, 6_000, 8_000].freeze

  ZERO_LIMITS = ([0] * 4).freeze

  LOW_LIMIT_PLANS = %w[
    bronze
    default
    early_adopter
    free
    premium_trial
    ultimate_trial
  ].freeze

  MID_LIMIT_PLANS = %w[
    premium
    silver
    ultimate_trial_paid_customer
  ].freeze

  HIGH_LIMIT_PLANS = %w[
    gold
    opensource
    ultimate
  ].freeze

  ALL_PLANS = (LOW_LIMIT_PLANS + MID_LIMIT_PLANS + HIGH_LIMIT_PLANS).freeze

  def up
    return unless Gitlab.com?

    LOW_LIMIT_PLANS.each do |plan_name|
      set_limits_for(plan_name, LOW_LIMITS)
    end

    MID_LIMIT_PLANS.each do |plan_name|
      set_limits_for(plan_name, MID_LIMITS)
    end

    HIGH_LIMIT_PLANS.each do |plan_name|
      set_limits_for(plan_name, HIGH_LIMITS)
    end
  end

  def down
    return unless Gitlab.com?

    ALL_PLANS.each do |plan_name|
      set_limits_for(plan_name, ZERO_LIMITS)
    end
  end

  private

  def set_limits_for(plan_name, limits)
    limits.each_with_index do |limit, i|
      create_or_update_plan_limit("import_placeholder_user_limit_tier_#{i + 1}", plan_name, limit)
    end
  end
end
