# frozen_string_literal: true

FactoryBot.define do
  factory :instance_statistics_measurement, class: 'Analytics::InstanceStatistics::Measurement' do
    recorded_at { Time.now }
    identifier { Analytics::InstanceStatistics::Measurement.identifiers[:projects] }
    count { 1_000 }
  end
end
