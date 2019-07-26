# frozen_string_literal: true

FactoryBot.define do
  factory :milestone do
    title

    transient do
      project nil
      group nil
      project_id nil
      group_id nil
      parent nil
    end

    trait :active do
      state "active"
    end

    trait :closed do
      state "closed"
    end

    trait :with_dates do
      start_date { Date.new(2000, 1, 1) }
      due_date { Date.new(2000, 1, 30) }
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
      elsif evaluator.parent
        id = evaluator.parent.id
        evaluator.parent.is_a?(Group) ? evaluator.group_id = id : evaluator.project_id = id
      else
        milestone.project = create(:project)
      end
    end

    factory :active_milestone, traits: [:active]
    factory :closed_milestone, traits: [:closed]
  end
end
