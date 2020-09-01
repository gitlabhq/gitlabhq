# frozen_string_literal: true

require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  model_class = Analytics::InstanceStatistics::Measurement
  recorded_at = Date.today

  # Insert random counts for the last 10 weeks
  measurements = 10.times.flat_map do
    recorded_at = (recorded_at - 1.week).end_of_week.end_of_day - 5.minutes

    model_class.identifiers.map do |_, id|
      {
        recorded_at: recorded_at,
        count: rand(1_000_000),
        identifier: id
      }
    end
  end

  model_class.upsert_all(measurements, unique_by: [:identifier, :recorded_at])

  print '.'
end
