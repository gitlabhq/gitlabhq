# frozen_string_literal: true

FactoryBot.define do
  factory :milestone, traits: [:has_internal_id] do
    title

    transient do
      project { nil }
      group { nil }
      project_id { nil }
      group_id { nil }
      resource_parent { nil }
    end

    trait :active do
      state { "active" }
    end

    trait :closed do
      state { "closed" }
    end

    trait :with_dates do
      start_date { Date.new(2000, 1, 1) }
      due_date { Date.new(2000, 1, 30) }
    end

    trait :on_project do
      project
    end

    trait :on_group do
      group
    end

    after(:build, :stub) do |milestone, evaluator|
      if evaluator.group
        milestone.group = evaluator.group
      elsif evaluator.group_id
        milestone.group_id = evaluator.group_id
      elsif evaluator.project
        milestone.project = evaluator.project
      elsif evaluator.project_id
        milestone.project_id = evaluator.project_id
      elsif evaluator.resource_parent
        id = evaluator.resource_parent.id
        evaluator.resource_parent.is_a?(Group) ? evaluator.group_id = id : evaluator.project_id = id
      else
        milestone.project = create(:project)
      end
    end

    factory :active_milestone, traits: [:active]
    factory :closed_milestone, traits: [:closed]
    factory :project_milestone, traits: [:on_project]
    factory :group_milestone, traits: [:on_group]
  end
end
