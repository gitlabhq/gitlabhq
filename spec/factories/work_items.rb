# frozen_string_literal: true

FactoryBot.define do
  factory :work_item, traits: [:has_internal_id] do
    title { generate(:title) }
    project
    author { project.creator }
    updated_by { author }
    relative_position { RelativePositioning::START_POSITION }
    issue_type { :issue }
    association :work_item_type, :default

    trait :confidential do
      confidential { true }
    end

    trait :task do
      issue_type { :task }
      association :work_item_type, :default, :task
    end

    trait :incident do
      issue_type { :incident }
      association :work_item_type, :default, :incident
    end

    trait :test_case do
      issue_type { :test_case }
      association :work_item_type, :default, :test_case
    end

    trait :last_edited_by_user do
      association :last_edited_by, factory: :user
    end

    trait :objective do
      issue_type { :objective }
      association :work_item_type, :default, :objective
    end

    trait :key_result do
      issue_type { :key_result }
      association :work_item_type, :default, :key_result
    end

    before(:create, :build) do |work_item, evaluator|
      if evaluator.namespace.present?
        work_item.project = nil
        work_item.namespace = evaluator.namespace
      end
    end
  end
end
