# frozen_string_literal: true

FactoryBot.define do
  factory :protected_branch do
    name
    project

    transient do
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

    trait :maintainers_can_push do
      transient do
        default_push_level false
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    after(:build) do |protected_branch, evaluator|
      if evaluator.default_access_level && evaluator.default_push_level
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end

      if evaluator.default_access_level && evaluator.default_merge_level
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    trait :no_one_can_merge do
      after(:create) do |protected_branch|
        protected_branch.merge_access_levels.first.update!(access_level: Gitlab::Access::NO_ACCESS)
      end
    end
  end
end
