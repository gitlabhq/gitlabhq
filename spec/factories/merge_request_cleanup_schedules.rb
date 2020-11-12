# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_cleanup_schedule, class: 'MergeRequest::CleanupSchedule' do
    merge_request
    scheduled_at { Time.current }
  end
end
