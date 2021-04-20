# frozen_string_literal: true

FactoryBot.define do
  factory :timelog do
    time_spent { 3600 }
    for_issue

    factory :issue_timelog,         traits: [:for_issue]
    factory :merge_request_timelog, traits: [:for_merge_request]

    trait :for_issue do
      issue
      user { issue.author }
    end

    trait :for_merge_request do
      merge_request
      issue { nil }
      user { merge_request.author }
    end
  end
end
