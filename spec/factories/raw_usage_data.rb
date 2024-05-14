# frozen_string_literal: true

FactoryBot.define do
  factory :raw_usage_data do
    recorded_at { Time.current }
    payload { { test: 'test' } }
    association :organization, factory: :organization
  end
end
