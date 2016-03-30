include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :ci_build, class: Ci::Build do
    name 'test'
    ref 'master'
    tag false
    created_at 'Di 29. Okt 09:50:00 CET 2013'
    started_at 'Di 29. Okt 09:51:28 CET 2013'
    finished_at 'Di 29. Okt 09:53:28 CET 2013'
    commands 'ls -a'
    options do
      {
        image: "ruby:2.1",
        services: ["postgres"]
      }
    end

    commit factory: :ci_commit

    trait :success do
      status 'success'
    end

    trait :failed do
      status 'failed'
    end

    trait :canceled do
      status 'canceled'
    end

    trait :running do
      status 'running'
    end

    trait :pending do
      status 'pending'
    end

    trait :allowed_to_fail do
      allow_failure true
    end

    after(:build) do |build, evaluator|
      build.project = build.commit.project
    end

    factory :ci_not_started_build do
      started_at nil
      finished_at nil
    end

    factory :ci_build_tag do
      tag true
    end

    factory :ci_build_with_coverage do
      coverage 99.9
    end

    trait :trace do
      after(:create) do |build, evaluator|
        build.trace = 'BUILD TRACE'
      end
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
  end
end
