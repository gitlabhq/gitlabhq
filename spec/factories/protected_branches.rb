FactoryBot.define do
  factory :protected_branch do
    name
    project

    transient do
      # EE
      authorize_user_to_push nil
      authorize_user_to_merge nil
      authorize_user_to_unprotect nil
      authorize_group_to_push nil
      authorize_group_to_merge nil
      authorize_group_to_unprotect nil

      default_push_level true
      default_merge_level true
      default_access_level true
    end

    trait :developers_can_push do
      transient do
        default_push_level false
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :developers_can_merge do
      transient do
        default_merge_level false
      end

      after(:build) do |protected_branch|
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_push do
      transient do
        default_push_level false
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::NO_ACCESS)
      end
    end

    trait :masters_can_push do
      transient do
        default_push_level false
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MASTER)
      end
    end

    after(:build) do |protected_branch, evaluator|
      # EE
      if user = evaluator.authorize_user_to_push
        protected_branch.push_access_levels.new(user: user)
      end

      if user = evaluator.authorize_user_to_merge
        protected_branch.merge_access_levels.new(user: user)
      end

      if user = evaluator.authorize_user_to_unprotect
        protected_branch.unprotect_access_levels.new(user: user)
      end

      if group = evaluator.authorize_group_to_push
        protected_branch.push_access_levels.new(group: group)
      end

      if group = evaluator.authorize_group_to_merge
        protected_branch.merge_access_levels.new(group: group)
      end

      if group = evaluator.authorize_group_to_unprotect
        protected_branch.unprotect_access_levels.new(group: group)
      end

      next unless protected_branch.merge_access_levels.empty?

      if evaluator.default_access_level && evaluator.default_push_level
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MASTER)
      end

      if evaluator.default_access_level && evaluator.default_merge_level
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::MASTER)
      end
    end

    trait :no_one_can_merge do
      after(:create) do |protected_branch|
        protected_branch.merge_access_levels.first.update!(access_level: Gitlab::Access::NO_ACCESS)
      end
    end
  end
end
