# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state_version, class: 'Terraform::StateVersion' do
    terraform_state factory: :terraform_state
    created_by_user factory: :user
    build { association(:ci_build, project: terraform_state.project) }

    sequence(:version)
    file { fixture_file_upload('spec/fixtures/terraform/terraform.tfstate', 'application/json') }
  end
end
