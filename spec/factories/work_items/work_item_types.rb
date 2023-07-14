# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_type, class: 'WorkItems::Type' do
    namespace

    name      { generate(:work_item_type_name) }
    base_type { WorkItems::Type.base_types[:issue] }
    icon_name { 'issue-type-issue' }

    initialize_with do
      type_base_attributes = attributes.with_indifferent_access.slice(:base_type, :namespace, :namespace_id)

      # Expect base_types to exist on the DB
      if type_base_attributes.slice(:namespace, :namespace_id).compact.empty?
        WorkItems::Type.find_or_initialize_by(type_base_attributes)
      else
        WorkItems::Type.new(attributes)
      end
    end

    trait :default do
      namespace { nil }
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
