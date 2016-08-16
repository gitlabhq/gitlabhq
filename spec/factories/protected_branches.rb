FactoryGirl.define do
  factory :protected_branch do
    name
    project

    before(:create) do |protected_branch|
      protected_branch.push_access_levels.new(access_level: Gitlab::Access::MASTER)
      protected_branch.merge_access_levels.new(access_level: Gitlab::Access::MASTER)
    end

    trait :developers_can_push do
      after(:create) do |protected_branch|
        protected_branch.push_access_levels.first.update!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :developers_can_merge do
      after(:create) do |protected_branch|
        protected_branch.merge_access_levels.first.update!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_push do
      after(:create) do |protected_branch|
        protected_branch.push_access_levels.first.update!(access_level: Gitlab::Access::NO_ACCESS)
      end
    end
  end
end
