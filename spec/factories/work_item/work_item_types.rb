# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_type, class: 'WorkItem::Type' do
    namespace

    name      { generate(:work_item_type_name) }
    base_type { WorkItem::Type.base_types[:issue] }
    icon_name { 'issue-type-issue' }

    trait :default do
      namespace { nil }
    end

    trait :incident do
      base_type { WorkItem::Type.base_types[:incident] }
      icon_name { 'issue-type-incident' }
    end

    trait :test_case do
      base_type { WorkItem::Type.base_types[:test_case] }
      icon_name { 'issue-type-test-case' }
    end

    trait :requirement do
      base_type { WorkItem::Type.base_types[:requirement] }
      icon_name { 'issue-type-requirements' }
    end
  end
end
