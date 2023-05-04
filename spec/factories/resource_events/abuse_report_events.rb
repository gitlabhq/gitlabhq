# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report_event, class: 'ResourceEvents::AbuseReportEvent' do
    action { :ban_user }
    abuse_report
    user
  end
end
