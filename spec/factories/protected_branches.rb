FactoryGirl.define do
  factory :protected_branch do
    name
    project

    after(:create) do |protected_branch|
      protected_branch.create_push_access_level!(access_level: Gitlab::Access::MASTER)
      protected_branch.create_merge_access_level!(access_level: Gitlab::Access::MASTER)
    end

    trait :developers_can_push do
      after(:create) do |protected_branch|
        protected_branch.push_access_level.update!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :developers_can_merge do
      after(:create) do |protected_branch|
        protected_branch.merge_access_level.update!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_push do
      after(:create) do |protected_branch|
        protected_branch.push_access_level.update!(access_level: Gitlab::Access::NO_ACCESS)
      end
    end
  end
end
