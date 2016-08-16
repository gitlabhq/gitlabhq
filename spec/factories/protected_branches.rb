FactoryGirl.define do
  factory :protected_branch do
    name
    project

    after(:build) do |protected_branch|
      protected_branch.push_access_levels.new(access_level: Gitlab::Access::MASTER)
      protected_branch.merge_access_levels.new(access_level: Gitlab::Access::MASTER)
    end

    transient do
      authorize_user_to_push nil
      authorize_user_to_merge nil
    end

    trait :remove_default_access_levels do
      after(:create) do |protected_branch|
        protected_branch.push_access_levels.destroy_all
        protected_branch.merge_access_levels.destroy_all
      end
    end

    trait :developers_can_push do
      after(:create) do |protected_branch|
        protected_branch.push_access_levels.create!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :developers_can_merge do
      after(:create) do |protected_branch|
        protected_branch.merge_access_levels.create!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_push do
      after(:create) do |protected_branch|
        protected_branch.push_access_levels.create!(access_level: Gitlab::Access::NO_ACCESS)
      end
    end

    trait :masters_can_push do
      after(:create) do |protected_branch|
        protected_branch.push_access_levels.create!(access_level: Gitlab::Access::MASTER)
      end
    end

    after(:create) do |protected_branch, evaluator|
      protected_branch.push_access_levels.create!(user: evaluator.authorize_user_to_push) if evaluator.authorize_user_to_push
      protected_branch.merge_access_levels.create!(user: evaluator.authorize_user_to_merge) if evaluator.authorize_user_to_merge
    end
  end
end
