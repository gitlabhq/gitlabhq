FactoryBot.define do
  factory :ci_runner, class: Ci::Runner do
    sequence(:description) { |n| "My runner#{n}" }

    platform  "darwin"
    active    true
    access_level :not_protected

    is_shared true
    runner_type :instance_type

    trait :online do
      contacted_at Time.now
    end

    trait :instance do
      is_shared true
      runner_type :instance_type
    end

    trait :group do
      is_shared false
      runner_type :group_type

      after(:build) do |runner, evaluator|
        runner.groups << build(:group) if runner.groups.empty?
      end
    end

    trait :project do
      is_shared false
      runner_type :project_type

      after(:build) do |runner, evaluator|
        runner.projects << build(:project) if runner.projects.empty?
      end
    end

    trait :without_projects do
      # we use that to create invalid runner:
      # the one without projects
      after(:create) do |runner, evaluator|
        runner.runner_projects.delete_all
      end
    end

    trait :inactive do
      active false
    end

    trait :ref_protected do
      access_level :ref_protected
    end
  end
end
