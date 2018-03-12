include ActionDispatch::TestProcess

FactoryBot.define do
  factory :ci_job_artifact, class: Ci::JobArtifact do
    job factory: :ci_build
    file_type :archive

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
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :correct_checksum do
      after(:build) do |artifact, evaluator|
        artifact.file_sha256 = Digest::SHA256.file(artifact.file.path).hexdigest
      end
    end
  end
end
