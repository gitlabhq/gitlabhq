# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state, class: 'Terraform::State' do
    project { association(:project) }

    sequence(:name) { |n| "state-#{n}" }

    trait :with_file do
      versioning_enabled { false }
      file { fixture_file_upload('spec/fixtures/terraform/terraform.tfstate', 'application/json') }
    end

    trait :locked do
      sequence(:lock_xid) { |n| "lock-#{n}" }
      locked_at { Time.current }
      locked_by_user { association(:user) }
    end

    trait :with_version do
      after(:create) do |state|
        create(:terraform_state_version, terraform_state: state)
      end
    end

    # Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/235108
    factory :legacy_terraform_state, parent: :terraform_state, traits: [:with_file]
  end
end
