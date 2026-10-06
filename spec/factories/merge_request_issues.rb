# frozen_string_literal: true

FactoryBot.define do
  factory :merge_request_issue do
    issue
    merge_request
  end
end
