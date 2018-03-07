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
        evaluator.parent.is_a?(Group) ? board.group_id = id : evaluator.project_id = id
      else
        milestone.project = create(:project)
      end
    end

    factory :active_milestone, traits: [:active]
    factory :closed_milestone, traits: [:closed]
  end
end
