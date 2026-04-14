# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_position, class: 'WorkItems::Position' do
    association :work_item
    namespace { work_item.namespace }
  end
end
