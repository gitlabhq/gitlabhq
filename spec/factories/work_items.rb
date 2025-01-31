# frozen_string_literal: true

FactoryBot.define do
  factory :work_item, traits: [:has_internal_id] do
    title { generate(:title) }
    project
    author { project.creator }
    updated_by { author }
    relative_position { RelativePositioning::START_POSITION }
    association :work_item_type

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

    trait :issue do
      association :work_item_type, :issue
    end

    trait :task do
      association :work_item_type, :task
    end

    trait :incident do
      association :work_item_type, :incident
    end

    trait :requirement do
      association :work_item_type, :requirement
    end

    trait :test_case do
      association :work_item_type, :test_case
    end

    trait :last_edited_by_user do
      association :last_edited_by, factory: :user
    end

    trait :objective do
      association :work_item_type, :objective
    end

    trait :key_result do
      association :work_item_type, :key_result
    end

    trait :epic do
      association :work_item_type, :epic
    end

    trait :ticket do
      association :work_item_type, :ticket
    end

    before(:create, :build) do |work_item, evaluator|
      if evaluator.namespace.present?
        work_item.project = nil
        work_item.namespace = evaluator.namespace
      end
    end

    # Service Desk Ticket
    factory :ticket do
      association :work_item_type, :ticket
    end
  end
end
