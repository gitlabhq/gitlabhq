FactoryBot.define do
  factory :issue do
    title { generate(:title) }
    project
    author { project.creator }
    updated_by { author }

    trait :confidential do
      confidential true
    end

    trait :opened do
      state :opened
    end

    trait :closed do
      state :closed
      closed_at { Time.now }
    end

    factory :closed_issue, traits: [:closed]
    factory :reopened_issue, traits: [:opened]

    factory :labeled_issue do
      transient do
        labels []
      end

      after(:create) do |issue, evaluator|
        issue.update(labels: evaluator.labels)
      end
    end
  end
end
