# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report_label_link, class: 'AntiAbuse::Reports::LabelLink' do
    abuse_report_label
    abuse_report
  end
end
