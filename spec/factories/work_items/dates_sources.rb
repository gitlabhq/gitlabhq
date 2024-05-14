# frozen_string_literal: true

FactoryBot.define do
  factory :work_items_dates_source, class: 'WorkItems::DatesSource' do
    work_item

    trait :fixed do
      due_date_fixed { due_date }
      due_date_is_fixed { true }
      start_date_fixed { start_date }
      start_date_is_fixed { true }
    end
  end
end
