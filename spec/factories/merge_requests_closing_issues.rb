# frozen_string_literal: true

FactoryBot.define do
  factory :merge_requests_closing_issues do
    issue
    merge_request
  end
end
