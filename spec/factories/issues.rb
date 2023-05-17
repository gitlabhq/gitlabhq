# frozen_string_literal: true

FactoryBot.define do
  factory :issue, traits: [:has_internal_id] do
    title { generate(:title) }
    project
    namespace { project.project_namespace }
    author { project.creator }
    updated_by { author }
    relative_position { RelativePositioning::START_POSITION }
    issue_type { :issue }
    association :work_item_type, :default

    trait :confidential do
      confidential { true }
    end

    trait :with_asc_relative_position do
      sequence(:relative_position) { |n| n * 1000 }
    end

    trait :with_desc_relative_position do
      sequence(:relative_position) { |n| -n * 1000 }
    end

    trait :opened do
      state_id { Issue.available_states[:opened] }
    end

    trait :locked do
      discussion_locked { true }
    end

    trait :closed do
      state_id { Issue.available_states[:closed] }
      closed_at { Time.now }
    end

    trait :with_alert do
      after(:create) do |issue|
        create(:alert_management_alert, project: issue.project, issue: issue)
      end
    end

    trait :closed_as_duplicate do
      closed
      after(:create) do |issue|
        issue.update!(duplicated_to: create(:issue, project: issue.project))
      end
    end

    after(:build) do |issue, evaluator|
      issue.state_id = Issue.available_states[evaluator.state]
    end

    factory :closed_issue, traits: [:closed]
    factory :reopened_issue, traits: [:opened]

    factory :labeled_issue do
      transient do
        labels { [] }
      end

      after(:create) do |issue, evaluator|
        issue.update!(labels: evaluator.labels)
      end
    end

    trait :requirement do
      issue_type { :requirement }
      association :work_item_type, :default, :requirement
    end

    trait :task do
      issue_type { :task }
      association :work_item_type, :default, :task
    end

    trait :objective do
      issue_type { :objective }
      association :work_item_type, :default, :objective
    end

    trait :key_result do
      issue_type { :key_result }
      association :work_item_type, :default, :key_result
    end

    trait :incident do
      issue_type { :incident }
      association :work_item_type, :default, :incident
    end

    trait :test_case do
      issue_type { :test_case }
      association :work_item_type, :default, :test_case
    end

    factory :incident do
      issue_type { :incident }
      association :work_item_type, :default, :incident

      # An escalation status record is created for all incidents
      # in app code. This is a trait to avoid creating escalation
      # status records in specs which do not need them.
      trait :with_escalation_status do
        after(:create) do |incident|
          create(:incident_management_issuable_escalation_status, issue: incident)
        end
      end
    end
  end
end
