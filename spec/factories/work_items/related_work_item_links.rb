# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_link, class: 'WorkItems::RelatedWorkItemLink' do
    source factory: :work_item
    target factory: :work_item
  end
end
