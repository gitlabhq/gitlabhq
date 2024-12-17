# frozen_string_literal: true

require_relative 'deployable'

FactoryBot.define do
  factory :ci_build, class: 'Ci::Build', parent: :ci_processable do
    instance_eval ::Factories::Ci::Deployable.traits

    name { 'test' }
    add_attribute(:protected) { false }
    created_at { 'Di 29. Okt 09:50:00 CET 2013' }
    scheduling_type { 'stage' }
    pending

    options do
      {
        image: 'image:1.0',
        services: ['postgres'],
        script: ['ls -a']
      }
    end

    yaml_variables do
      [
        { key: 'DB_NAME', value: 'postgres', public: true }
      ]
    end

    project { pipeline.project }

    ref { pipeline.ref }

    runner_manager { nil }

    execution_config { nil }

    after(:build) do |build, evaluator|
      if evaluator.runner_manager
        build.runner = evaluator.runner_manager.runner
        create(:ci_runner_machine_build, build: build, runner_manager: evaluator.runner_manager)
      end
    end

    trait :with_token do
      transient do
        generate_token { true }
      end

      after(:build) do |build, evaluator|
        build.ensure_token if evaluator.generate_token
      end
    end

    trait :with_build_name do
      after(:create) do |build, _|
        create(:ci_build_name, build: build)
      end
    end

    trait :with_build_source do
      after(:create) do |build, _|
        create(:ci_build_source, build: build)
      end
    end

    trait :degenerated do
      options { nil }
      yaml_variables { nil }
      execution_config { nil }
    end

    trait :unique_name do
      name { generate(:job_name) }
    end

    trait :matrix do
      sequence(:name) { |n| "job: [#{n}]" }
      options do
        {
          parallel: {
            total: 2,
            matrix: [{ ID: %w[1 2] }]
          }
        }
      end
    end

    trait :dependent do
      scheduling_type { 'dag' }

      transient do
        sequence(:needed_name) { |n| "dependency #{n}" }
        needed { association(:ci_build, name: needed_name, pipeline: pipeline) }
      end

      after(:create) do |build, evaluator|
        build.needs << create(:ci_build_need, build: build, name: evaluator.needed.name)
      end
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

    trait :canceling do
      started
      status { 'canceling' }
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

    trait :waiting_for_callback do
      started
      status { 'waiting_for_callback' }
    end

    trait :pending do
      with_token
      queued_at { 'Di 29. Okt 09:50:59 CET 2013' }

      status { 'pending' }
    end

    trait :created do
      status { 'created' }
      generate_token { false }
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

    trait :allowed_to_fail do
      allow_failure { true }
    end

    trait :ignored do
      allowed_to_fail
    end

    trait :playable do
      manual
    end

    trait :with_manual_confirmation do
      options do
        {
          manual_confirmation: 'Please confirm. Do you want to proceed?'
        }
      end
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
      trigger_request { association :ci_trigger_request, project_id: pipeline.project_id }
    end

    trait :tag do
      tag { true }
    end

    trait :coverage do
      coverage { 99.9 }
      coverage_regex { '/(d+)/' }
    end

    trait :trace_with_coverage do
      coverage { nil }
      coverage_regex { '(\d+\.\d+)%' }

      transient do
        trace_coverage { 60.0 }
      end

      after(:create) do |build, evaluator|
        Gitlab::ExclusiveLease.skipping_transaction_check do
          build.trace.send(:unsafe_set, "Coverage #{evaluator.trace_coverage}%")
        end
        build.trace.archive! if build.complete?
      end
    end

    trait :trace_live do
      after(:create) do |build, evaluator|
        Gitlab::ExclusiveLease.skipping_transaction_check do
          # We can skip calling `Ci::Build#hide_secrets` because this content is safe.
          # This allows not to call into potentialy unstubbed ApplicationSetting in specs.
          # For example: `ci_job_token_signing_key` when in `let_it_be` context.
          build.trace.send(:unsafe_set, 'BUILD TRACE')
        end
      end
    end

    trait :trace_artifact do
      after(:create) do |build, evaluator|
        create(:ci_job_artifact, :trace, job: build)
      end
    end

    trait :unarchived_trace_artifact do
      after(:create) do |build, evaluator|
        create(:ci_job_artifact, :unarchived_trace_artifact, job: build)
      end
    end

    trait :trace_with_duplicate_sections do
      after(:create) do |build, evaluator|
        trace = File.binread(
          File.expand_path(
            Rails.root.join('spec/fixtures/trace/trace_with_duplicate_sections')))

        Gitlab::ExclusiveLease.skipping_transaction_check do
          build.trace.send(:unsafe_set, trace)
        end
      end
    end

    trait :trace_with_sections do
      after(:create) do |build, evaluator|
        trace = File.binread(
          File.expand_path(
            Rails.root.join('spec/fixtures/trace/trace_with_sections')))

        Gitlab::ExclusiveLease.skipping_transaction_check do
          build.trace.send(:unsafe_set, trace)
        end
      end
    end

    trait :unicode_trace_live do
      after(:create) do |build, evaluator|
        trace = File.binread(
          File.expand_path(
            Rails.root.join('spec/fixtures/trace/ansi-sequence-and-unicode')))

        build.trace.send(:unsafe_set, trace)
      end
    end

    trait :erased do
      erased_at { Time.now }
      erased_by factory: :user
    end

    trait :queued do
      queued_at { Time.now }

      after(:create) do |build|
        build.create_queuing_entry!
      end
    end

    trait :picked do
      running

      runner factory: :ci_runner

      after(:create) do |build|
        ::Ci::RunningBuild.upsert_build!(build)
      end
    end

    trait :pages do
      ref { "HEAD" }
      name { 'pages' }

      after(:create) do |build, _evaluator|
        file = fixture_file_upload("spec/fixtures/pages.zip")
        metadata = fixture_file_upload("spec/fixtures/pages.zip.meta")

        create(:ci_job_artifact, :correct_checksum, file: file, job: build)
        create(:ci_job_artifact, file_type: :metadata, file_format: :gzip, file: metadata, job: build)
        build.reload
      end
    end

    trait :artifacts do
      after(:create) do |build, evaluator|
        create(:ci_job_artifact, :archive, :public, job: build, expire_at: build.artifacts_expire_at)
        create(:ci_job_artifact, :metadata, :public, job: build, expire_at: build.artifacts_expire_at)
        build.reload
      end
    end

    trait :private_artifacts do
      after(:create) do |build, evaluator|
        create(:ci_job_artifact, :archive, :private, job: build, expire_at: build.artifacts_expire_at)
        create(:ci_job_artifact, :metadata, :private, job: build, expire_at: build.artifacts_expire_at)
        build.reload
      end
    end

    trait :no_access_artifacts do
      after(:create) do |build, evaluator|
        create(:ci_job_artifact, :archive, :none, job: build, expire_at: build.artifacts_expire_at)
        create(:ci_job_artifact, :metadata, :none, job: build, expire_at: build.artifacts_expire_at)
        build.reload
      end
    end

    trait :report_results do
      after(:build) do |build|
        build.report_results << build(:ci_build_report_result)
      end
    end

    trait :codequality_report do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :codequality, job: build)
      end
    end

    trait :sast_report do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :sast, job: build)
      end
    end

    trait :secret_detection_report do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :secret_detection, job: build)
      end
    end

    trait :test_reports do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :junit, job: build)
      end
    end

    trait :test_reports_with_attachment do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :junit_with_attachment, job: build)
      end
    end

    trait :broken_test_reports do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :junit_with_corrupted_data, job: build)
      end
    end

    trait :test_reports_with_duplicate_failed_test_names do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :junit_with_duplicate_failed_test_names, job: build)
      end
    end

    trait :test_reports_with_three_failures do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :junit_with_three_failures, job: build)
      end
    end

    trait :accessibility_reports do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :accessibility, job: build)
      end
    end

    trait :coverage_reports do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :cobertura, job: build)
      end
    end

    trait :codequality_reports do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :codequality, job: build)
      end
    end

    trait :codequality_reports_without_degradation do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :codequality_without_errors, job: build)
      end
    end

    trait :terraform_reports do
      after(:build) do |build|
        build.job_artifacts << build(:ci_job_artifact, :terraform, job: build)
      end
    end

    trait :expired do
      artifacts_expire_at { 1.minute.ago }
    end

    trait :with_artifacts_paths do
      options do
        {
          artifacts: {
            name: 'artifacts_file',
            untracked: false,
            paths: ['out/'],
            when: 'always',
            expire_in: '7d'
          }
        }
      end
    end

    trait :with_commit do
      after(:build) do |build|
        commit = build(:commit, :without_author)
        stub_method(build, :commit) { commit }
      end
    end

    trait :with_commit_and_author do
      after(:build) do |build|
        commit = build(:commit)
        stub_method(build, :commit) { commit }
      end
    end

    trait :extended_options do
      options do
        {
          image: { name: 'image:1.0', entrypoint: '/bin/sh' },
          services: ['postgres',
                     { name: 'docker:stable-dind', entrypoint: '/bin/sh', command: 'sleep 30', alias: 'docker' },
                     { name: 'mysql:latest', variables: { MYSQL_ROOT_PASSWORD: 'root123.' } }],
          script: %w[echo],
          after_script: %w[ls date],
          hooks: { pre_get_sources_script: ["echo 'hello pre_get_sources_script'"] },
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
            policy: 'pull-push',
            when: 'on_success'
          }
        }
      end
    end

    trait :release_options do
      options do
        {
          only: 'tags',
          script: ['make changelog | tee release_changelog.txt'],
          release: {
            name: 'Release $CI_COMMIT_SHA',
            description: 'Created using the release-cli $EXTRA_DESCRIPTION',
            tag_name: 'release-$CI_COMMIT_SHA',
            ref: '$CI_COMMIT_SHA',
            assets: { links: [{ name: 'asset1', url: 'https://example.com/assets/1' }] }
          }
        }
      end
    end

    trait :no_options do
      options { {} }
    end

    trait :coverage_report_cobertura do
      options do
        {
          artifacts: {
            expire_in: '7d',
            reports: {
              coverage_report: {
                coverage_format: 'cobertura',
                path: 'cobertura.xml'
              }
            }
          }
        }
      end
    end

    # TODO: move Security traits to ee_ci_build
    # https://gitlab.com/gitlab-org/gitlab/-/issues/210486
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

    trait :secret_detection do
      options do
        {
            artifacts: { reports: { secret_detection: 'gl-secret-detection-report.json' } }
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

    trait :cluster_image_scanning do
      options do
        {
            artifacts: { reports: { cluster_image_scanning: 'gl-cluster-image-scanning-report.json' } }
        }
      end
    end

    trait :coverage_fuzzing do
      options do
        {
          artifacts: { reports: { coverage_fuzzing: 'gl-coverage-fuzzing-report.json' } }
        }
      end
    end

    trait :license_scanning do
      options do
        {
          artifacts: { reports: { license_scanning: 'gl-license-scanning-report.json' } }
        }
      end
    end

    trait :multiple_report_artifacts do
      options do
        {
            artifacts: {
              reports: {
                sast: 'gl-sast-report.json',
                container_scanning: 'gl-container-scanning-report.json'
              }
            }
        }
      end
    end

    trait :with_private_artifacts_config do
      options do
        {
          artifacts: { public: false }
        }
      end
    end

    trait :with_developer_access_artifacts do
      options do
        {
          artifacts: { access: 'developer' }
        }
      end
    end

    # invalid case for access setting
    trait :with_access_and_public_setting do
      options do
        {
          artifacts: {
            public: true,
            access: 'all'
          }
        }
      end
    end

    trait :with_none_access_artifacts do
      options do
        {
          artifacts: { access: 'none' }
        }
      end
    end

    trait :with_public_artifacts_config do
      options do
        {
          artifacts: { public: true }
        }
      end
    end

    trait :with_all_access_artifacts do
      options do
        {
          artifacts: { access: 'all' }
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

    trait :forward_deployment_failure do
      failed
      failure_reason { 13 }
    end

    trait :deployment_rejected do
      failed
      failure_reason { 22 }
    end

    trait :with_runner_session do
      after(:build) do |build|
        build.build_runner_session(url: 'https://gitlab.example.com')
      end
    end
  end
end
