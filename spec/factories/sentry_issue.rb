# frozen_string_literal: true

FactoryBot.define do
  factory :sentry_issue, class: 'SentryIssue' do
    issue
    sequence(:sentry_issue_identifier) { |n| 10000000 + n }
  end
end
