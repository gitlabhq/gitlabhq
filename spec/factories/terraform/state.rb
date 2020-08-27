# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state, class: 'Terraform::State' do
    project { create(:project) }

    sequence(:name) { |n| "state-#{n}" }

    trait :with_file do
      file { fixture_file_upload('spec/fixtures/terraform/terraform.tfstate', 'application/json') }
    end

    trait :locked do
      sequence(:lock_xid) { |n| "lock-#{n}" }
      locked_at { Time.current }
      locked_by_user { create(:user) }
    end

    trait(:checksummed) do
      with_file
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      with_file
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
