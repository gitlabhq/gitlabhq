# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_provider_gcp, class: Clusters::Providers::Gcp do
    association :cluster, platform_type: :kubernetes, provider_type: :gcp
    gcp_project_id { 'test-gcp-project' }

    trait :scheduled do
      access_token { 'access_token_123' }
    end

    trait :creating do
      access_token { 'access_token_123' }

      after(:build) do |gcp, evaluator|
        gcp.make_creating('operation-123')
      end
    end

    trait :created do
      endpoint { '111.111.111.111' }

      after(:build) do |gcp, evaluator|
        gcp.make_created
      end
    end

    trait :errored do
      after(:build) do |gcp, evaluator|
        gcp.make_errored('Something wrong')
      end
    end

    trait :abac_enabled do
      legacy_abac { true }
    end

    trait :cloud_run_enabled do
      cloud_run { true }
    end
  end
end
