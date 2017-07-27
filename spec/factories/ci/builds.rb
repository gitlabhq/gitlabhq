include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :ci_build, class: Ci::Build do
    name 'test'
    stage 'test'
    stage_idx 0
    ref 'master'
    tag false
    status 'pending'
    created_at 'Di 29. Okt 09:50:00 CET 2013'
    started_at 'Di 29. Okt 09:51:28 CET 2013'
    finished_at 'Di 29. Okt 09:53:28 CET 2013'
    commands 'ls -a'

    options do
      {
        image: 'ruby:2.1',
        services: ['postgres']
      }
    end

    yaml_variables do
      [
        { key: 'DB_NAME', value: 'postgres', public: true }
      ]
    end

    pipeline factory: :ci_pipeline

    trait :success do
      status 'success'
    end

    trait :failed do
      status 'failed'
    end

    trait :canceled do
      status 'canceled'
    end

    trait :skipped do
      status 'skipped'
    end

    trait :running do
      status 'running'
    end

    trait :pending do
      status 'pending'
    end

    trait :created do
      status 'created'
    end

    trait :manual do
      status 'manual'
      self.when 'manual'
    end

    trait :teardown_environment do
      environment 'staging'
      options environment: { name: 'staging',
                             action: 'stop',
                             url: 'http://staging.example.com/$CI_JOB_NAME' }
    end

    trait :allowed_to_fail do
      allow_failure true
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

    trait :retried do
      retried true
    end

    trait :cancelable do
      pending
    end

    trait :erasable do
      success
      artifacts
    end

    trait :tags do
      tag_list [:docker, :ruby]
    end

    trait :on_tag do
      tag true
    end

    trait :triggered do
      trigger_request factory: :ci_trigger_request_with_variables
    end

    after(:build) do |build, evaluator|
      build.project ||= build.pipeline.project
    end

    factory :ci_not_started_build do
      started_at nil
      finished_at nil
    end

    factory :ci_build_tag do
      tag true
    end

    trait :coverage do
      coverage 99.9
      coverage_regex '/(d+)/'
    end

    trait :trace do
      after(:create) do |build, evaluator|
        build.trace.set('BUILD TRACE')
      end
    end

    trait :unicode_trace do
      after(:create) do |build, evaluator|
        trace = File.binread(
          File.expand_path(
            Rails.root.join('spec/fixtures/trace/ansi-sequence-and-unicode')))

        build.trace.set(trace)
      end
    end

    trait :erased do
      erased_at Time.now
      erased_by factory: :user
    end

    trait :queued do
      queued_at Time.now
      runner factory: :ci_runner
    end

    trait :artifacts do
      after(:create) do |build, _|
        build.artifacts_file =
          fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'),
                             'application/zip')

        build.artifacts_metadata =
          fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'),
                             'application/x-gzip')

        build.save!
      end
    end

    trait :remote_store do
      artifacts_file_store ArtifactUploader::REMOTE_STORE
      artifacts_metadata_store ArtifactUploader::REMOTE_STORE
    end

    trait :artifacts_expired do
      after(:create) do |build, _|
        build.artifacts_file =
          fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'),
            'application/zip')

        build.artifacts_metadata =
          fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'),
            'application/x-gzip')

        build.artifacts_expire_at = 1.minute.ago

        build.save!
      end
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
            services: ['postgres', { name: 'docker:dind', entrypoint: '/bin/sh', command: 'sleep 30', alias: 'docker' }],
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

    trait :non_playable do
      status 'created'
      self.when 'manual'
    end
  end
end
