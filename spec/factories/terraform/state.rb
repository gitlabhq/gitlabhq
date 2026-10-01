# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state, class: 'Terraform::State' do
    project { association(:project) }

    sequence(:name) { |n| "state-#{n}" }

    trait :locked do
      sequence(:lock_xid) { |n| "lock-#{n}" }
      locked_at { Time.current }
      locked_by_user { association(:user) }
    end

    trait :deletion_in_progress do
      deleted_at { Time.current }
    end

    trait :with_version do
      versions { [association(:terraform_state_version, strategy: :build, terraform_state: instance)] }
    end
  end
end
