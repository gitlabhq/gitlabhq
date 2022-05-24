# frozen_string_literal: true

FactoryBot.define do
  factory :timelog_category, class: 'TimeTracking::TimelogCategory' do
    namespace

    name { generate(:name) }
  end
end
