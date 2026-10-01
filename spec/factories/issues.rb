# frozen_string_literal: true

FactoryBot.define do
  factory :issue, traits: [:has_internal_id] do
    title { generate(:title) }
    project
    namespace { project.project_namespace }
    author { project.creator }
    updated_by { author }
    relative_position { RelativePositioning::START_POSITION }
    association :work_item_type, factory: :work_item_system_defined_type

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
      alert_management_alert do
        association(:alert_management_alert, strategy: :build, project: project, issue: instance)
      end
    end

    trait :closed_as_duplicate do
      closed
      duplicated_to { association(:issue, project: project) }
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

    trait :task do
      association :work_item_type, :task, factory: :work_item_system_defined_type
    end

    trait :incident do
      association :work_item_type, :incident, factory: :work_item_system_defined_type
    end

    trait :ticket do
      association :work_item_type, :ticket, factory: :work_item_system_defined_type
    end

    trait :service_desk do
      association :author, :support_bot
    end

    factory :incident do
      association :work_item_type, :incident, factory: :work_item_system_defined_type

      # An escalation status record is created for all incidents
      # in app code. This is a trait to avoid creating escalation
      # status records in specs which do not need them.
      trait :with_escalation_status do
        incident_management_issuable_escalation_status do
          association(:incident_management_issuable_escalation_status, strategy: :build, issue: instance)
        end
      end
    end
  end
end
