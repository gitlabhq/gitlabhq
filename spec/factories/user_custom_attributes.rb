# frozen_string_literal: true

FactoryBot.define do
  factory :user_custom_attribute do
    user
    sequence(:key) { |n| "key#{n}" }
    sequence(:value) { |n| "value#{n}" }

    trait :assumed_high_risk_reason do
      key { UserCustomAttribute::ASSUMED_HIGH_RISK_REASON }
      value { 'reason' }
    end
  end
end
