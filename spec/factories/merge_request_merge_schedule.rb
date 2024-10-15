# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_merge_schedule, class: 'MergeRequests::MergeSchedule' do
    merge_request
  end
end
