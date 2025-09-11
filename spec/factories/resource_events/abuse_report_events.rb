# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report_event, class: 'ResourceEvents::AbuseReportEvent' do
    action { :ban_user }
    abuse_report
    user

    after(:build) do |event, evaluator|
      event.organization ||= evaluator.abuse_report.organization
    end
  end
end
