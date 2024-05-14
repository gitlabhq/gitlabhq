# frozen_string_literal: true

module Factories
  module Ci
    module Deployable
      def self.traits
        <<-RUBY
          trait :teardown_environment do
            environment { 'staging' }
            options do
              {
                script: %w(ls),
                environment: { name: 'staging',
                              action: 'stop',
                              url: 'http://staging.example.com/$CI_JOB_NAME' }
              }
            end
          end

          trait :environment_with_deployment_tier do
            environment { 'test_portal' }
            options do
              {
                script: %w(ls),
                environment: { name: 'test_portal',
                              action: 'start',
                              url: 'http://staging.example.com/$CI_JOB_NAME',
                              deployment_tier: 'testing' }
              }
            end
          end

          trait :deploy_to_production do
            environment { 'production' }

            options do
              {
                script: %w(ls),
                environment: { name: 'production',
                              url: 'http://prd.example.com/$CI_JOB_NAME' }
              }
            end
          end

          trait :start_review_app do
            environment { 'review/$CI_COMMIT_REF_NAME' }

            options do
              {
                script: %w(ls),
                environment: { name: 'review/$CI_COMMIT_REF_NAME',
                              url: 'http://staging.example.com/$CI_JOB_NAME',
                              on_stop: 'stop_review_app' }
              }
            end
          end

          trait :stop_review_app do
            name { 'stop_review_app' }
            environment { 'review/$CI_COMMIT_REF_NAME' }

            options do
              {
                script: %w(ls),
                environment: { name: 'review/$CI_COMMIT_REF_NAME',
                              url: 'http://staging.example.com/$CI_JOB_NAME',
                              action: 'stop' }
              }
            end
          end

          trait :prepare_staging do
            name { 'prepare staging' }
            environment { 'staging' }

            options do
              {
                script: %w(ls),
                environment: { name: 'staging', action: 'prepare' }
              }
            end

            set_expanded_environment_name
          end

          trait :start_staging do
            name { 'start staging' }
            environment { 'staging' }

            options do
              {
                script: %w(ls),
                environment: { name: 'staging', action: 'start' }
              }
            end

            set_expanded_environment_name
          end

          trait :stop_staging do
            name { 'stop staging' }
            environment { 'staging' }

            options do
              {
                script: %w(ls),
                environment: { name: 'staging', action: 'stop' }
              }
            end

            set_expanded_environment_name
          end

          trait :set_expanded_environment_name do
            after(:build) do |job, evaluator|
              job.assign_attributes(
                metadata_attributes: {
                  expanded_environment_name: job.expanded_environment_name
                }
              )
            end
          end

          trait :deploy_job do
            name { 'deploy job' }
            environment { 'env' }

            options do
              {
                script: %w(ls),
                environment: { name: environment, action: 'start' }
              }
            end

            set_expanded_environment_name
          end

          trait :with_deployment do
            after(:build) do |job, evaluator|
              ##
              # Build deployment/environment relations if environment name is set
              # to the job. If `job.deployment` has already been set, it doesn't
              # build a new instance.
              Environments::CreateForJobService.new.execute(job)
            end

            after(:create) do |job, evaluator|
              Deployments::CreateForJobService.new.execute(job)
            end
          end
        RUBY
      end
    end
  end
end
