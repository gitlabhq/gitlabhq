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
  end
end
