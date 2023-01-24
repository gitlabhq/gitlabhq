# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_stage, class: 'Analytics::CycleAnalytics::Stage' do
    sequence(:name) { |n| "Stage ##{n}" }
    start_event_identifier { Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestCreated.identifier }
    end_event_identifier { Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged.identifier }

    namespace { association(:group) }
    value_stream { association(:cycle_analytics_value_stream, namespace: namespace) }
  end
end
