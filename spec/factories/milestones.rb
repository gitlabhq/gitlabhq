FactoryGirl.define do
  factory :milestone do
    title
    project

    trait :closed do
      state :closed
    end

    factory :closed_milestone, traits: [:closed]
  end
end
