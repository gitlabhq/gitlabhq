FactoryGirl.define do
  factory :ci_runner, class: Ci::Runner do
    sequence :description do |n|
      "My runner#{n}"
    end

    platform  "darwin"
    is_shared false
    active    true

    trait :shared do
      is_shared true
    end

    trait :inactive do
      active false
    end
  end
end
