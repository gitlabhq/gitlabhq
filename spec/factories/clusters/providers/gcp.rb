# frozen_string_literal: true

FactoryBot.define do
  factory :cluster_provider_gcp, class: 'Clusters::Providers::Gcp' do
    association :cluster, platform_type: :kubernetes, provider_type: :gcp
    gcp_project_id { 'test-gcp-project' }

    trait :scheduled do
      status { 1 }
      access_token { 'access_token_123' }
    end

    trait :creating do
      access_token { 'access_token_123' }
      status { 2 }
      operation_id { 'operation-123' }
    end

    trait :created do
      endpoint { '111.111.111.111' }
      status { 3 }
    end

    trait :errored do
      status { 4 }
      status_reason { 'Something wrong' }
    end

    trait :abac_enabled do
      legacy_abac { true }
    end

    trait :cloud_run_enabled do
      cloud_run { true }
    end
  end
end
