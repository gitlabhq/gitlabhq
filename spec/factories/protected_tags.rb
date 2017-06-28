FactoryGirl.define do
  factory :protected_tag do
    name
    project

    after(:build) do |protected_tag|
      protected_tag.create_access_levels.new(access_level: Gitlab::Access::MASTER)
    end

    trait :developers_can_create do
      after(:create) do |protected_tag|
        protected_tag.create_access_levels.first.update!(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :no_one_can_create do
      after(:create) do |protected_tag|
        protected_tag.create_access_levels.first.update!(access_level: Gitlab::Access::NO_ACCESS)
      end
    end
  end
end
