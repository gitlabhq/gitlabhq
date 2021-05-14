# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_project_value_stream, class: 'Analytics::CycleAnalytics::ProjectValueStream' do
    sequence(:name) { |n| "Value Stream ##{n}" }

    project
  end
end
