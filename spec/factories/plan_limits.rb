# frozen_string_literal: true

FactoryBot.define do
  factory :plan_limits do
    plan

    trait :default_plan do
      plan factory: :default_plan
    end
  end
end
