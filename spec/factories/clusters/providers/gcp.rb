FactoryBot.define do
  factory :cluster_provider_gcp, class: Clusters::Providers::Gcp do
    cluster
    gcp_project_id 'test-gcp-project'

    trait :scheduled do
      access_token 'access_token_123'
    end

    trait :creating do
      access_token 'access_token_123'

      after(:build) do |gcp, evaluator|
        gcp.make_creating('operation-123')
      end
    end

    trait :created do
      endpoint '111.111.111.111'

      after(:build) do |gcp, evaluator|
        gcp.make_created
      end
    end

    trait :errored do
      after(:build) do |gcp, evaluator|
        gcp.make_errored('Something wrong')
      end
    end
  end
end
