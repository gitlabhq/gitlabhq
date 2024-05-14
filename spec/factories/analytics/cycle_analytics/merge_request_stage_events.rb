# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_analytics_merge_request_stage_event, class: 'Analytics::CycleAnalytics::MergeRequestStageEvent' do
    sequence(:stage_event_hash_id) { |n| n }
    sequence(:merge_request_id) { 0 }
    sequence(:group_id) { 0 }
    sequence(:project_id) { 0 }

    start_event_timestamp { 3.weeks.ago.to_date }
    end_event_timestamp { 2.weeks.ago.to_date }
    duration_in_milliseconds do
      if start_event_timestamp && end_event_timestamp
        (end_event_timestamp.to_time - start_event_timestamp.to_time).in_milliseconds
      end
    end
  end
end
