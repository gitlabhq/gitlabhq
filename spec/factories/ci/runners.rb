FactoryBot.define do
  factory :ci_runner, class: Ci::Runner do
    sequence(:description) { |n| "My runner#{n}" }

    platform  "darwin"
    active    true
    access_level :not_protected

    is_shared true
    runner_type :instance_type

    trait :instance do
      is_shared true
      runner_type :instance_type
    end

    trait :group do
      is_shared false
      runner_type :group_type
    end

    trait :project do
      is_shared false
      runner_type :project_type
    end

    trait :inactive do
      active false
    end

    trait :ref_protected do
      access_level :ref_protected
    end
  end
end
