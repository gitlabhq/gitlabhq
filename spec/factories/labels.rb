FactoryBot.define do
  trait :base_label do
    title { generate(:label_title) }
    color "#990000"
  end

  factory :label, traits: [:base_label], class: ProjectLabel do
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

  factory :group_label, traits: [:base_label] do
    group
  end
end
