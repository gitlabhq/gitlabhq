# frozen_string_literal: true

FactoryBot.define do
  factory :ci_platform_metric do
    recorded_at { Time.zone.now }
    platform_target { generate(:title) }
    count { SecureRandom.random_number(100) + 1 }
  end
end
