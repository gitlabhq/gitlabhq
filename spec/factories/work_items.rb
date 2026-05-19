# frozen_string_literal: true

FactoryBot.define do
  factory :work_item, traits: [:has_internal_id] do
    title { generate(:title) }
    project
    author { project.creator }
    updated_by { author }
    relative_position { RelativePositioning::START_POSITION }
    association :work_item_type, factory: :work_item_system_defined_type

    trait :confidential do
      confidential { true }
    end

    trait :opened do
      state_id { WorkItem.available_states[:opened] }
    end

    trait :locked do
      discussion_locked { true }
    end

    trait :closed do
      state_id { WorkItem.available_states[:closed] }
      closed_at { Time.now }
    end

    trait :closed_as_duplicate do
      closed
      association :duplicated_to, factory: :work_item
    end

    trait :group_level do
      project { nil }
      association :namespace, factory: :group
      association :author, factory: :user
    end

    trait :user_namespace_level do
      project { nil }
      association :namespace, factory: :user_namespace
      association :author, factory: :user
    end

    trait :last_edited_by_user do
      association :last_edited_by, factory: :user
    end

    trait :issue do
      association :work_item_type, :issue, factory: :work_item_system_defined_type
    end

    trait :task do
      association :work_item_type, :task, factory: :work_item_system_defined_type
    end

    trait :incident do
      association :work_item_type, :incident, factory: :work_item_system_defined_type
    end

    trait :ticket do
      association :work_item_type, :ticket, factory: :work_item_system_defined_type
    end

    # rubocop:disable Gitlab/AvoidDirectWorkItemTypeUsage -- Necessary to mock EE types
    trait :requirement do
      work_item_type { WorkItems::TypesFramework::SystemDefined::Type.new(id: 4) }
    end

    trait :test_case do
      work_item_type { WorkItems::TypesFramework::SystemDefined::Type.new(id: 3) }
    end

    trait :objective do
      work_item_type { WorkItems::TypesFramework::SystemDefined::Type.new(id: 6) }
    end

    trait :key_result do
      work_item_type { WorkItems::TypesFramework::SystemDefined::Type.new(id: 7) }
    end

    trait :epic do
      work_item_type { WorkItems::TypesFramework::SystemDefined::Type.new(id: 8) }
    end
    # rubocop:enable Gitlab/AvoidDirectWorkItemTypeUsage

    before(:create, :build) do |work_item, evaluator|
      if evaluator.namespace.present?
        work_item.project = nil
        work_item.namespace = evaluator.namespace
      end
    end

    # Service Desk Ticket
    factory :ticket do
      association :work_item_type, :ticket, factory: :work_item_system_defined_type
    end
  end
end
