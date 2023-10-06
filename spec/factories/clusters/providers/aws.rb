# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_provider_aws, class: 'Clusters::Providers::Aws' do
    association :cluster, platform_type: :kubernetes, provider_type: :aws

    kubernetes_version { '1.16' }
    role_arn { 'arn:aws:iam::123456789012:role/role-name' }
    vpc_id { 'vpc-00000000000000000' }
    subnet_ids { %w[subnet-00000000000000000 subnet-11111111111111111] }
    security_group_id { 'sg-00000000000000000' }
    key_name { 'user' }

    trait :scheduled do
      access_key_id { 'access_key_id' }
      secret_access_key { 'secret_access_key' }
      session_token { 'session_token' }
    end

    trait :creating do
      after(:build) do |provider|
        provider.make_creating
      end
    end

    trait :created do
      after(:build) do |provider|
        provider.make_created
      end
    end

    trait :errored do
      after(:build) do |provider|
        provider.make_errored('An error occurred')
      end
    end
  end
end
