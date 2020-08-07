# frozen_string_literal: true

FactoryBot.define do
  sequence(:sequential_date) do |n|
    n.days.from_now
  end

  factory :iteration do
    title
    start_date { generate(:sequential_date) }
    due_date { generate(:sequential_date) }

    transient do
      project { nil }
      group { nil }
      project_id { nil }
      group_id { nil }
      resource_parent { nil }
    end

    trait :upcoming do
      state_enum { Iteration::STATE_ENUM_MAP[:upcoming] }
    end

    trait :started do
      state_enum { Iteration::STATE_ENUM_MAP[:started] }
    end

    trait :closed do
      state_enum { Iteration::STATE_ENUM_MAP[:closed] }
    end

    trait(:skip_future_date_validation) do
      after(:stub, :build) do |iteration|
        iteration.skip_future_date_validation = true
      end
    end

    trait(:skip_project_validation) do
      after(:stub, :build) do |iteration|
        iteration.skip_project_validation = true
      end
    end

    after(:build, :stub) do |iteration, evaluator|
      if evaluator.group
        iteration.group = evaluator.group
      elsif evaluator.group_id
        iteration.group_id = evaluator.group_id
      elsif evaluator.project
        iteration.project = evaluator.project
      elsif evaluator.project_id
        iteration.project_id = evaluator.project_id
      elsif evaluator.resource_parent
        id = evaluator.resource_parent.id
        evaluator.resource_parent.is_a?(Group) ? evaluator.group_id = id : evaluator.project_id = id
      else
        iteration.group = create(:group)
      end
    end

    factory :upcoming_iteration, traits: [:upcoming]
    factory :started_iteration, traits: [:started]
    factory :closed_iteration, traits: [:closed]
  end
end
