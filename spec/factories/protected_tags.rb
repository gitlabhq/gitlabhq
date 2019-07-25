# frozen_string_literal: true

FactoryBot.define do
  factory :protected_tag do
    name
    project

    transient do
      default_access_level true
    end

    trait :developers_can_create do
      transient do
        default_access_level false
      end

      after(:build) do |protected_tag|
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_create do
      transient do
        default_access_level false
      end

      after(:build) do |protected_tag|
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::NO_ACCESS)
      end
    end

    trait :maintainers_can_create do
      transient do
        default_access_level false
      end

      after(:build) do |protected_tag|
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    after(:build) do |protected_tag, evaluator|
      if evaluator.default_access_level
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end
  end
end
