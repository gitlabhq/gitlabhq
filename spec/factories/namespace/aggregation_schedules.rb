# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_aggregation_schedules, class: 'Namespace::AggregationSchedule' do
    namespace
  end
end
