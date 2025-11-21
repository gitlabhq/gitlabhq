# frozen_string_literal: true

FactoryBot.define do
  factory :custom_dashboard_search_data, class: 'Search::CustomDashboardSearchData' do
    association :custom_dashboard, factory: :custom_dashboard

    name { FFaker::Lorem.sentence }
    description { FFaker::Lorem.paragraph }
  end
end
