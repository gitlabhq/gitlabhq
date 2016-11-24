FactoryGirl.define do
  factory :label, class: ProjectLabel do
    sequence(:title) { |n| "label#{n}" }
    color "#990000"
    project

    transient do
      priority nil
    end

    after(:create) do |label, evaluator|
      if evaluator.priority
        label.priorities.create(project: label.project, priority: evaluator.priority)
      end
    end
  end

  factory :group_label, class: GroupLabel do
    sequence(:title) { |n| "label#{n}" }
    color "#990000"
    group
  end
end
