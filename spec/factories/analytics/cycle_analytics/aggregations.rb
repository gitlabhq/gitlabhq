# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_aggregation, class: 'Analytics::CycleAnalytics::Aggregation' do
    namespace { association(:group, :with_organization) }

    enabled { true }

    trait :disabled do
      enabled { false }
    end

    trait :enabled do
      enabled { true }
    end

    factory :cycle_analytics_stage_aggregation, class: 'Analytics::CycleAnalytics::StageAggregation' do
      stage { association(:cycle_analytics_stage, namespace: namespace) }
    end
  end
end
