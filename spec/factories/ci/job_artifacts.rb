require "#{Rails.root}/spec/support/fixture_helpers.rb"

include ActionDispatch::TestProcess
include FixtureHelpers

FactoryBot.define do
  factory :ci_job_artifact, class: Ci::JobArtifact do
    job factory: :ci_build
    file_type :archive

    trait :remote_store do
      file_store JobArtifactUploader::Store::REMOTE
    end

    after :build do |artifact|
      artifact.project ||= artifact.job.project
    end

    trait :archive do
      file_type :archive

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
      end
    end

    trait :metadata do
      file_type :metadata

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'), 'application/x-gzip')
      end
    end

    trait :trace do
      file_type :trace

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          expand_fixture_path('trace/sample_trace'), 'text/plain')
      end
    end
  end
end
