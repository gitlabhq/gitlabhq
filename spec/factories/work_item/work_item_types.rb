# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_type, class: 'WorkItem::Type' do
    namespace

    name      { generate(:work_item_type_name) }
    icon_name { 'issue' }
    base_type { Issue.issue_types['issue'] }

    trait :default do
      namespace { nil }
    end
  end
end
