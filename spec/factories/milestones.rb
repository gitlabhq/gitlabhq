FactoryGirl.define do
  factory :milestone do
    title
    project

    trait :active do
      state "active"
    end

    trait :closed do
      state "closed"
    end

    factory :active_milestone, traits: [:active]
    factory :closed_milestone, traits: [:closed]
  end
end
