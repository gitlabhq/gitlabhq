# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_type, class: 'WorkItems::Type' do
    name      { generate(:work_item_type_name) }
    base_type { WorkItems::Type.base_types[:issue] }
    icon_name { 'issue-type-issue' }

    transient do
      default { true }
    end

    initialize_with do
      next WorkItems::Type.new(attributes) unless default

      type_base_attributes = attributes.with_indifferent_access.slice(:base_type)

      # Expect base_types to exist on the DB
      WorkItems::Type.find_or_initialize_by(type_base_attributes)
    end

    # non_default work item types don't exist in production. This trait only exists to simplify work item type
    # specific specs and prevent coupling with existing default types
    trait :non_default do
      default { false }
      sequence(:id, 100) { |n| n }
      sequence(:correct_id, 100) { |n| n }
    end

    trait :issue do
      base_type { WorkItems::Type.base_types[:issue] }
      icon_name { 'issue-type-issue' }
    end

    trait :incident do
      base_type { WorkItems::Type.base_types[:incident] }
      icon_name { 'issue-type-incident' }
    end

    trait :test_case do
      base_type { WorkItems::Type.base_types[:test_case] }
      icon_name { 'issue-type-test-case' }
    end

    trait :requirement do
      base_type { WorkItems::Type.base_types[:requirement] }
      icon_name { 'issue-type-requirements' }
    end

    trait :task do
      base_type { WorkItems::Type.base_types[:task] }
      icon_name { 'issue-type-task' }
    end
  end
end
