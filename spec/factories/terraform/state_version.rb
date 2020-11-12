# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state_version, class: 'Terraform::StateVersion' do
    terraform_state factory: :terraform_state
    created_by_user factory: :user
    build { association(:ci_build, project: terraform_state.project) }

    sequence(:version)
    file { fixture_file_upload('spec/fixtures/terraform/terraform.tfstate', 'application/json') }

    trait(:checksummed) do
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
