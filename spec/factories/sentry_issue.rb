# frozen_string_literal: true

FactoryBot.define do
  factory :sentry_issue, class: 'SentryIssue' do
    issue
    sentry_issue_identifier { 1234567891 }
  end
end
