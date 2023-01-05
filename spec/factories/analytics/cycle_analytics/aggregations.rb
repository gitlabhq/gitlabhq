# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_aggregation, class: 'Analytics::CycleAnalytics::Aggregation' do
    namespace { association(:group) }

    enabled { true }

    trait :disabled do
      enabled { false }
    end

    trait :enabled do
      enabled { true }
    end
  end
end
