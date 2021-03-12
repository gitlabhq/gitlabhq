# frozen_string_literal: true

require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  chance_for_decrement = 0.1 # 10% chance that we'll generate smaller count than the previous count
  max_increase = 10000
  max_decrease = 1000

  model_class = Analytics::UsageTrends::Measurement

  # Skip generating data for billable_users, to avoid license check problems
  measurements = model_class.identifiers.except(:billable_users).each_value.flat_map do |id|
    recorded_at = 60.days.ago
    current_count = rand(1_000_000)

    # Insert random counts for the last 60 days
    Array.new(60) do
      recorded_at = (recorded_at + 1.day).end_of_day - 5.minutes

      # Normally our counts should slowly increase as the gitlab instance grows.
      # Small chance (10%) to have a slight decrease (simulating cleanups, bulk delete)
      if rand < chance_for_decrement
        current_count -= rand(max_decrease)
      else
        current_count += rand(max_increase)
      end

      {
        recorded_at: recorded_at,
        count: current_count,
        identifier: id
      }
    end
  end

  model_class.upsert_all(measurements, unique_by: [:identifier, :recorded_at])

  print '.'
end
