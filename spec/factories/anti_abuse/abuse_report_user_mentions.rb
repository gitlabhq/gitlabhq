# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report_user_mention, class: 'AntiAbuse::Reports::UserMention' do
    note
    abuse_report

    after(:build) do |event, evaluator|
      event.organization ||= evaluator.abuse_report.organization
    end
  end
end
