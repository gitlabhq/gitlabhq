# frozen_string_literal: true

FactoryBot.define do
  factory :terraform_state_protection_rule, class: 'Terraform::StateProtectionRule' do
    project
    state_name { 'production' }
    minimum_access_level_for_write { :maintainer }
    allowed_from { :anywhere }
  end
end
