# frozen_string_literal: true

include ActionDispatch::TestProcess

FactoryBot.define do
  factory :ci_build, class: Ci::Build do
    name { 'test' }
    stage { 'test' }
    stage_idx { 0 }
    ref { 'master' }
    tag { false }
    add_attribute(:protected) { false }
    created_at { 'Di 29. Okt 09:50:00 CET 2013' }
    pending

    options do
      {
        image: 'ruby:2.1',
        services: ['postgres'],
        script: ['ls -a']
      }
    end

    yaml_variables do
      [
        { key: 'DB_NAME', value: 'postgres', public: true }
      ]
    end

    pipeline factory: :ci_pipeline

    trait :degenerated do
      options { nil }
      yaml_variables { nil }
    end

    trait :started do
      started_at { 'Di 29. Okt 09:51:28 CET 2013' }
    end

    trait :finished do
      started
      finished_at { 'Di 29. Okt 09:53:28 CET 2013' }
    end

    trait :success do
      finished
      status { 'success' }
    end

    trait :failed do
      finished
      status { 'failed' }
    end

    trait :canceled do
      finished
      status { 'canceled' }
    end

    trait :skipped do
      started
      status { 'skipped' }
    end

    trait :running do
      started
      status { 'running' }
    end

    trait :pending do
      queued_at { 'Di 29. Okt 09:50:59 CET 2013' }
      status { 'pending' }
    end

    trait :created do
      status { 'created' }
    end

    trait :preparing do
      status { 'preparing' }
    end

    trait :scheduled do
      schedulable
      status { 'scheduled' }
      scheduled_at { 1.minute.since }
    end

    trait :expired_scheduled do
      schedulable
      status { 'scheduled' }
      scheduled_at { 1.minute.ago }
    end

    trait :manual do
      status { 'manual' }
      self.when { 'manual' }
    end

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

    trait :allowed_to_fail do
      allow_failure { true }
    end

    trait :ignored do
      allowed_to_fail
    end

    trait :playable do
      manual
    end

    trait :retryable do
      success
    end

    trait :schedulable do
      self.when { 'delayed' }

      options do
        {
          script: ['ls -a'],
          start_in: '1 minute'
        }
      end
    end

    trait :actionable do
      self.when { 'manual' }
    end

    trait :retried do
      retried { true }
    end

    trait :cancelable do
      pending
    end

    trait :erasable do
      success
      artifacts
    end

    trait :tags do
      tag_list do
        [:docker, :ruby]
      end
    end

    trait :on_tag do
      tag { true }
    end

    trait :triggered do
      trigger_request factory: :ci_trigger_request
    end

    after(:build) do |build, evaluator|
      build.project ||= build.pipeline.project
    end

    trait :with_deployment do
      after(:build) do |build, evaluator|
        ##
        # Build deployment/environment relations if environment name is set
        # to the job. If `build.deployment` has already been set, it doesn't
        # build a new instance.
        build.deployment =
          Gitlab::Ci::Pipeline::Seed::Deployment.new(build).to_resource
      end
    end

    trait :tag do
      tag { true }
    end

    trait :coverage do
      coverage { 99.9 }
      coverage_regex { '/(d+)/' }
    end

    trait :trace_live do
      after(:create) do |build, evaluator|
        build.trace.set('BUILD TRACE')
      end
    end

    trait :trace_artifact do
      after(:create) do |build, evaluator|
        create(:ci_job_artifact, :trace, job: build)
      end
    end

    trait :trace_with_duplicate_sections do
      after(:create) do |build, evaluator|
        trace = File.binread(
          File.expand_path(
            Rails.root.join('spec/fixtures/trace/trace_with_duplicate_sections')))

        build.trace.set(trace)
      end
    end

    trait :trace_with_sections do
      after(:create) do |build, evaluator|
        trace = File.binread(
          File.expand_path(
            Rails.root.join('spec/fixtures/trace/trace_with_sections')))

        build.trace.set(trace)
      end
    end

    trait :unicode_trace_live do
      after(:create) do |build, evaluator|
        trace = File.binread(
          File.expand_path(
            Rails.root.join('spec/fixtures/trace/ansi-sequence-and-unicode')))

        build.trace.set(trace)
      end
    end

    trait :erased do
      erased_at { Time.now }
      erased_by factory: :user
    end

    trait :queued do
      queued_at { Time.now }
      runner factory: :ci_runner
    end

    trait :artifacts do
      after(:create) do |build|
        create(:ci_job_artifact, :archive, job: build, expire_at: build.artifacts_expire_at)
        create(:ci_job_artifact, :metadata, job: build, expire_at: build.artifacts_expire_at)
        build.reload
      end
    end

    trait :test_reports do
      after(:build) do |build|
        build.job_artifacts << create(:ci_job_artifact, :junit, job: build)
      end
    end

    trait :expired do
      artifacts_expire_at { 1.minute.ago }
    end

    trait :with_commit do
      after(:build) do |build|
        allow(build).to receive(:commit).and_return build(:commit, :without_author)
      end
    end

    trait :with_commit_and_author do
      after(:build) do |build|
        allow(build).to receive(:commit).and_return build(:commit)
      end
    end

    trait :extended_options do
      options do
        {
          image: { name: 'ruby:2.1', entrypoint: '/bin/sh' },
          services: ['postgres', { name: 'docker:stable-dind', entrypoint: '/bin/sh', command: 'sleep 30', alias: 'docker' }],
          script: %w(echo),
          after_script: %w(ls date),
          artifacts: {
            name: 'artifacts_file',
            untracked: false,
            paths: ['out/'],
            when: 'always',
            expire_in: '7d'
          },
          cache: {
            key: 'cache_key',
            untracked: false,
            paths: ['vendor/*'],
            policy: 'pull-push'
          }
        }
      end
    end

    trait :no_options do
      options { {} }
    end

    trait :dast do
      options do
        {
            artifacts: { reports: { dast: 'gl-dast-report.json' } }
        }
      end
    end

    trait :sast do
      options do
        {
            artifacts: { reports: { sast: 'gl-sast-report.json' } }
        }
      end
    end

    trait :dependency_scanning do
      options do
        {
            artifacts: { reports: { dependency_scanning: 'gl-dependency-scanning-report.json' } }
        }
      end
    end

    trait :container_scanning do
      options do
        {
            artifacts: { reports: { container_scanning: 'gl-container-scanning-report.json' } }
        }
      end
    end

    trait :license_management do
      options do
        {
            artifacts: { reports: { license_management: 'gl-license-management-report.json' } }
        }
      end
    end

    trait :non_playable do
      status { 'created' }
      self.when { 'manual' }
    end

    trait :protected do
      add_attribute(:protected) { true }
    end

    trait :script_failure do
      failed
      failure_reason { 1 }
    end

    trait :api_failure do
      failed
      failure_reason { 2 }
    end

    trait :prerequisite_failure do
      failed
      failure_reason { 10 }
    end

    trait :with_runner_session do
      after(:build) do |build|
        build.build_runner_session(url: 'https://localhost')
      end
    end
  end
end
