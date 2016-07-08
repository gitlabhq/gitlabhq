FactoryGirl.define do
  factory :protected_branch do
    name
    project

    after(:create) do |protected_branch|
      protected_branch.create_push_access_level!(access_level: :masters)
      protected_branch.create_merge_access_level!(access_level: :masters)
    end

    trait :developers_can_push do
      after(:create) { |protected_branch| protected_branch.push_access_level.developers! }
    end

    trait :developers_can_merge do
      after(:create) { |protected_branch| protected_branch.merge_access_level.developers! }
    end

    trait :no_one_can_push do
      after(:create) { |protected_branch| protected_branch.push_access_level.no_one! }
    end
  end
end
