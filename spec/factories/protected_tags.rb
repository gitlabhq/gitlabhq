FactoryGirl.define do
  factory :protected_tag do
    name
    project

    after(:build) do |protected_tag|
      protected_tag.create_access_levels.new(access_level: Gitlab::Access::MASTER)
    end

    transient do
      authorize_user_to_create nil
      authorize_group_to_create nil
    end

    trait :remove_default_access_levels do
      after(:build) do |protected_tag|
        protected_tag.create_access_levels = []
      end
    end

    trait :developers_can_create do
      after(:create) do |protected_tag|
        protected_tag.create_access_levels.create!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_create do
      after(:create) do |protected_tag|
        protected_tag.create_access_levels.create!(access_level: Gitlab::Access::NO_ACCESS)
      end
    end

    trait :masters_can_create do
      after(:create) do |protected_tag|
        protected_tag.create_access_levels.create!(access_level: Gitlab::Access::MASTER)
      end
    end

    after(:create) do |protected_tag, evaluator|
      protected_tag.create_access_levels.create!(user: evaluator.authorize_user_to_create) if evaluator.authorize_user_to_create
      protected_tag.create_access_levels.create!(group: evaluator.authorize_group_to_create) if evaluator.authorize_group_to_create
    end
  end
end
