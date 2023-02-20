# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_value_stream, class: 'Analytics::CycleAnalytics::ValueStream' do
    sequence(:name) { |n| "Value Stream ##{n}" }

    namespace { association(:group) }
  end
end
