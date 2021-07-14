# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_cleanup_schedule, class: 'MergeRequest::CleanupSchedule' do
    merge_request
    scheduled_at { 1.day.ago }

    trait :running do
      status { MergeRequest::CleanupSchedule::STATUSES[:running] }
    end

    trait :completed do
      status { MergeRequest::CleanupSchedule::STATUSES[:completed] }
      completed_at { Time.current }
    end

    trait :failed do
      status { MergeRequest::CleanupSchedule::STATUSES[:failed] }
    end
  end
end
