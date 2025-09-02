# frozen_string_literal: true

FactoryBot.define do
  factory :merge_requests_merge_data, class: 'MergeRequests::MergeData' do
    merge_request { association(:merge_request) }
    project { merge_request.project }
  end
end
