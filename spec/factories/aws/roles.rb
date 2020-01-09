# frozen_string_literal: true

FactoryBot.define do
  factory :aws_role, class: 'Aws::Role' do
    user

    role_arn { 'arn:aws:iam::123456789012:role/role-name' }
    sequence(:role_external_id) { |n| "external-id-#{n}" }
  end
end
