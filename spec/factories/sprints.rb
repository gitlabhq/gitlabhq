# frozen_string_literal: true

FactoryBot.define do
  factory :sprint do
    title

    transient do
      project { nil }
      group { nil }
      project_id { nil }
      group_id { nil }
      resource_parent { nil }
    end

    trait :active do
      state { Sprint::STATE_ID_MAP[:active] }
    end

    trait :closed do
      state { Sprint::STATE_ID_MAP[:closed] }
    end

    trait :with_dates do
      start_date { Date.new(2000, 1, 1) }
      due_date { Date.new(2000, 1, 30) }
    end

    after(:build, :stub) do |sprint, evaluator|
      if evaluator.group
        sprint.group = evaluator.group
      elsif evaluator.group_id
        sprint.group_id = evaluator.group_id
      elsif evaluator.project
        sprint.project = evaluator.project
      elsif evaluator.project_id
        sprint.project_id = evaluator.project_id
      elsif evaluator.resource_parent
        id = evaluator.resource_parent.id
        evaluator.resource_parent.is_a?(Group) ? evaluator.group_id = id : evaluator.project_id = id
      else
        sprint.project = create(:project)
      end
    end

    factory :active_sprint, traits: [:active]
    factory :closed_sprint, traits: [:closed]
  end
end
