# frozen_string_literal: true

class SeedServiceDeskEmailRateLimits < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '19.4'

  HOURLY_LIMITS = {
    'free' => 100,
    'ultimate_trial' => 100,
    'premium_trial' => 100,
    'ultimate_trial_paid_customer' => 0,
    'premium' => 5000,
    'opensource' => 1500,
    'ultimate' => 0
  }.freeze

  DAILY_LIMITS = {
    'free' => 700,
    'ultimate_trial' => 700,
    'premium_trial' => 700,
    'ultimate_trial_paid_customer' => 0,
    'premium' => 50000,
    'opensource' => 10000,
    'ultimate' => 0
  }.freeze

  def up
    HOURLY_LIMITS.each do |plan, limit|
      create_or_update_plan_limit('service_desk_outbound_emails_per_hour', plan, limit)
    end

    DAILY_LIMITS.each do |plan, limit|
      create_or_update_plan_limit('service_desk_outbound_emails_per_day', plan, limit)
    end
  end

  def down
    HOURLY_LIMITS.each_key do |plan|
      create_or_update_plan_limit('service_desk_outbound_emails_per_hour', plan, 0)
      create_or_update_plan_limit('service_desk_outbound_emails_per_day', plan, 0)
    end
  end
end
