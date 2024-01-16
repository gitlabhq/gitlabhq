# frozen_string_literal: true

FactoryBot.define do
  factory :work_items_dates_source, class: 'WorkItems::DatesSource' do
    work_item
  end
end
