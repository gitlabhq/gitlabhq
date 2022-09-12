# frozen_string_literal: true

FactoryBot.define do
  factory :protected_branch do
    sequence(:name) { |n| "protected_branch_#{n}" }
    project

    transient do
      default_push_level { true }
      default_merge_level { true }
      default_access_level { true }
    end

    after(:create) do |protected_branch, evaluator|
      break unless protected_branch.project&.persisted?

      ProtectedBranches::CacheService.new(protected_branch.project).refresh
    end

    after(:build) do |protected_branch, evaluator|
      if evaluator.default_access_level && evaluator.default_push_level
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end

      if evaluator.default_access_level && evaluator.default_merge_level
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    trait :create_branch_on_repository do
      association :project, factory: [:project, :repository]

      transient do
        repository_branch_name { name }
      end

      after(:create) do |protected_branch, evaluator|
        project = protected_branch.project

        project.repository.create_branch(evaluator.repository_branch_name, project.default_branch_or_main)
      end
    end

    trait :maintainers_can_push do
      transient do
        default_push_level { false }
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    trait :maintainers_can_merge do
      transient do
        default_push_level { false }
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    trait :developers_can_push do
      transient do
        default_push_level { false }
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :developers_can_merge do
      transient do
        default_merge_level { false }
      end

      after(:build) do |protected_branch|
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_push do
      transient do
        default_push_level { false }
      end

      after(:build) do |protected_branch|
        protected_branch.push_access_levels.new(access_level: Gitlab::Access::NO_ACCESS)
      end
    end

    trait :no_one_can_merge do
      transient do
        default_merge_level { false }
      end

      after(:build) do |protected_branch|
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::NO_ACCESS)
      end
    end
  end
end
