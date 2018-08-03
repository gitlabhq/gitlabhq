# frozen_string_literal: true
FactoryBot.define do
  factory :build_environment_deployment, class: Ci::BuildEnvironmentDeployment do
    build factory: :ci_build
    environment

    trait :with_deployment do
      deployment
    end
  end
end
