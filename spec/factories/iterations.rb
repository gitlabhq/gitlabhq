# frozen_string_literal: true

FactoryBot.define do
  factory :iteration do
    title

    transient do
      project { nil }
      group { nil }
      project_id { nil }
      group_id { nil }
      resource_parent { nil }
    end

    trait :active do
      state { Iteration::STATE_ID_MAP[:active] }
    end

    trait :closed do
      state { Iteration::STATE_ID_MAP[:closed] }
    end

    trait :with_dates do
      start_date { Date.new(2000, 1, 1) }
      due_date { Date.new(2000, 1, 30) }
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
        iteration.project = create(:project)
      end
    end

    factory :active_iteration, traits: [:active]
    factory :closed_iteration, traits: [:closed]
  end
end
