# frozen_string_literal: true

FactoryBot.define do
  factory :job_environment, class: 'Environments::Job' do
    project
    environment { association :environment, project: project }
    pipeline { association :ci_pipeline, project: project }
    job { association :ci_build, pipeline: pipeline }

    expanded_environment_name { environment.name }

    options do
      {
        action: 'start',
        deployment_tier: 'production'
      }
    end

    trait :with_deployment do
      deployment { association :deployment, project: project, environment: environment }
    end
  end
end
