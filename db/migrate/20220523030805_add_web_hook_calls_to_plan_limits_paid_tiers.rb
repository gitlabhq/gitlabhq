# frozen_string_literal: true

class AddWebHookCallsToPlanLimitsPaidTiers < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MAX_RATE_LIMIT_NAME = 'web_hook_calls'
  MID_RATE_LIMIT_NAME = 'web_hook_calls_mid'
  MIN_RATE_LIMIT_NAME = 'web_hook_calls_low'

  UP_FREE_LIMITS = {
    MAX_RATE_LIMIT_NAME => 500,
    MID_RATE_LIMIT_NAME => 500,
    MIN_RATE_LIMIT_NAME => 500
  }.freeze

  UP_PREMIUM_LIMITS = {
    MAX_RATE_LIMIT_NAME => 4_000,
    MID_RATE_LIMIT_NAME => 2_800,
    MIN_RATE_LIMIT_NAME => 1_600
  }.freeze

  UP_ULTIMATE_LIMITS = {
    MAX_RATE_LIMIT_NAME => 13_000,
    MID_RATE_LIMIT_NAME => 9_000,
    MIN_RATE_LIMIT_NAME => 6_000
  }.freeze

  DOWN_FREE_LIMITS = {
    # 120 is the value for 'free' migrated in `db/migrate/20210601131742_update_web_hook_calls_limit.rb`
    MAX_RATE_LIMIT_NAME => 120,
    MID_RATE_LIMIT_NAME => 0,
    MIN_RATE_LIMIT_NAME => 0
  }.freeze

  DOWN_PAID_LIMITS = {
    MAX_RATE_LIMIT_NAME => 0,
    MID_RATE_LIMIT_NAME => 0,
    MIN_RATE_LIMIT_NAME => 0
  }.freeze

  def up
    return unless Gitlab.com?

    apply_limits('free', UP_FREE_LIMITS)

    # Apply Premium limits
    apply_limits('bronze', UP_PREMIUM_LIMITS)
    apply_limits('silver', UP_PREMIUM_LIMITS)
    apply_limits('premium', UP_PREMIUM_LIMITS)
    apply_limits('premium_trial', UP_PREMIUM_LIMITS)

    # Apply Ultimate limits
    apply_limits('gold', UP_ULTIMATE_LIMITS)
    apply_limits('ultimate', UP_ULTIMATE_LIMITS)
    apply_limits('ultimate_trial', UP_ULTIMATE_LIMITS)
    apply_limits('opensource', UP_ULTIMATE_LIMITS)
  end

  def down
    return unless Gitlab.com?

    apply_limits('free', DOWN_FREE_LIMITS)

    apply_limits('bronze', DOWN_PAID_LIMITS)
    apply_limits('silver', DOWN_PAID_LIMITS)
    apply_limits('premium', DOWN_PAID_LIMITS)
    apply_limits('premium_trial', DOWN_PAID_LIMITS)
    apply_limits('gold', DOWN_PAID_LIMITS)
    apply_limits('ultimate', DOWN_PAID_LIMITS)
    apply_limits('ultimate_trial', DOWN_PAID_LIMITS)
    apply_limits('opensource', DOWN_PAID_LIMITS)
  end

  private

  def apply_limits(plan_name, limits)
    limits.each_pair do |limit_name, limit|
      create_or_update_plan_limit(limit_name, plan_name, limit)
    end
  end
end
