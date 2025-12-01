# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_system_defined_type, class: 'WorkItems::SystemDefined::Type' do
    skip_create
    issue

    initialize_with do
      WorkItems::SystemDefined::Type.find(attributes[:id] || 1)
    end

    trait :issue do
      id { 1 }
      base_type { 'issue' }
    end

    trait :incident do
      id { 2 }
      base_type { 'incident' }
    end

    trait :task do
      id { 5 }
      base_type { 'task' }
    end

    trait :ticket do
      id { 9 }
      base_type { 'ticket' }
    end
  end
end
