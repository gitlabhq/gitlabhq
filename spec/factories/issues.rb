FactoryGirl.define do
  sequence :issue_created_at do |n|
    4.hours.ago + ( 2 * n ).seconds
  end

  factory :issue do
    title
    author
    project

    trait :confidential do
      confidential true
    end

    trait :closed do
      state :closed
    end

    trait :reopened do
      state :reopened
    end

    factory :closed_issue, traits: [:closed]
    factory :reopened_issue, traits: [:reopened]

    factory :labeled_issue do
      transient do
        labels []
      end

      after(:create) do |issue, evaluator|
        issue.update_attributes(labels: evaluator.labels)
      end
    end
  end
end
