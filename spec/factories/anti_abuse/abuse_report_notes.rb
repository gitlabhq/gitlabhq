# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report_notes, class: 'AntiAbuse::Reports::Note' do
    abuse_report { association(:abuse_report) }
    note { generate(:title) }
    author { association(:user) }
    updated_by { author }
  end
end
