FactoryBot.define do
  factory :protected_tag do
    name
    project

    transient do
      # EE
      authorize_user_to_create nil
      authorize_group_to_create nil

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

    trait :masters_can_create do
      transient do
        default_access_level false
      end

      after(:build) do |protected_tag|
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::MASTER)
      end
    end

    after(:build) do |protected_tag, evaluator|
      # EE
      if evaluator.authorize_user_to_create
        protected_tag.create_access_levels.new(user: evaluator.authorize_user_to_create)
      end

      if evaluator.authorize_group_to_create
        protected_tag.create_access_levels.new(group: evaluator.authorize_group_to_create)
      end

      if evaluator.default_access_level
        protected_tag.create_access_levels.new(access_level: Gitlab::Access::MASTER)
      end
    end
  end
end
