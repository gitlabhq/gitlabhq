# frozen_string_literal: true

FactoryBot.define do
  factory :deployment, class: 'Deployment' do
    sha { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    ref { 'master' }
    tag { false }
    user { nil }
    project { nil }
    deployable { association :ci_build, environment: environment.name, pipeline: association(:ci_pipeline, project: environment.project) }
    environment factory: :environment

    after(:build) do |deployment, evaluator|
      deployment.project ||= deployment.environment.project
      deployment.user ||= deployment.project.creator

      unless deployment.project.repository_exists?
        stub_method(deployment.project.repository, :create_ref) { nil }
      end

      if deployment.cluster && deployment.cluster.project_type? && deployment.cluster.project.nil?
        deployment.cluster.projects << deployment.project
      end
    end

    trait :review_app do
      sha { TestEnv::BRANCH_SHA['pages-deploy'] }
      ref { 'pages-deploy' }
    end

    trait :on_cluster do
      deployment_cluster factory: %i[deployment_cluster provided_by_gcp]
    end

    trait :on_cluster_not_managed do
      deployment_cluster factory: %i[deployment_cluster not_managed]
    end

    trait :running do
      status { :running }
    end

    trait :success do
      status { :success }
      finished_at { Time.now }
    end

    trait :failed do
      status { :failed }
      finished_at { Time.now }
    end

    trait :canceled do
      status { :canceled }
      finished_at { Time.now }
    end

    trait :created do
      status { :created }
    end

    trait :blocked do
      status { :blocked }
    end

    # This trait hooks the state maechine's events
    trait :succeed do
      after(:create) do |deployment, evaluator|
        deployment.succeed!
      end
    end

    trait :with_bridge do
      deployable { association :ci_bridge, environment: environment.name, pipeline: association(:ci_pipeline, project: environment.project) }
    end
  end
end
