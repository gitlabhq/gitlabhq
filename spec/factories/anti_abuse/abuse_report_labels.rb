# frozen_string_literal: true

FactoryBot.define do
  factory :abuse_report_label, class: 'AntiAbuse::Reports::Label' do
    title { generate(:label_title) }
  end
end
