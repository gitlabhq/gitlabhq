# frozen_string_literal: true

FactoryBot.define do
  factory :hierarchy_restriction, class: 'WorkItems::HierarchyRestriction' do
    parent_type { association :work_item_type, :default }
    child_type { association :work_item_type, :default }
  end
end
